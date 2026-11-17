import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/consent_ports.dart';
import '../domain/consent_record.dart';

/// What to do with `consent_required` (EK-16, ADR-0011 pkt 7, ADR-0012 pkt 5).
enum ConsentRequiredAction {
  /// EK-03 (privacy policy) or EK-06 with `aiConsentUpdatedIntro` (AI).
  askAgain,

  /// The app already synced a record in its built-in version, the server wants a newer
  /// one: "Update the app" (no loop back to the consent screen).
  updateApp,
}

/// AI consent state for P3-05 (EK-05/EK-06/EK-13).
enum AiConsentState {
  /// Never decided, or only a record older than the version built into the app.
  notGiven,

  /// Latest record granted, version >= the app's.
  granted,

  /// Latest record withdrawn (`granted=false`).
  withdrawn,
}

/// Result of [ConsentService.syncPending].
class SyncOutcome {
  const SyncOutcome({
    required this.synced,
    required this.remaining,
    this.failure,
  });

  final int synced;
  final int remaining;

  /// First failure that stopped the sync, if any.
  final AppFailure? failure;

  bool get complete => remaining == 0;
}

/// Consent rules of the client (US-003; ADR-0004, ADR-0005 pkt 3 + Aneks A pkt 4,
/// ADR-0011 pkt 1, 7, 10; ADR-0012 pkt 5).
class ConsentService {
  ConsentService({
    required ConsentLocalStore local,
    required PendingPolicyStore pending,
    required ConsentApi api,
    required String Function() newId,
    DateTime Function()? now,
    this.policyVersion = AppConstants.privacyPolicyVersion,
    this.aiConsentVersion = AppConstants.aiConsentVersion,
  }) : _local = local, // ignore: prefer_initializing_formals
       _pending = pending, // ignore: prefer_initializing_formals
       _api = api, // ignore: prefer_initializing_formals
       _newId = newId, // ignore: prefer_initializing_formals
       _now = now ?? DateTime.now;

  final ConsentLocalStore _local;
  final PendingPolicyStore _pending;
  final ConsentApi _api;
  final String Function() _newId;
  final DateTime Function() _now;

  /// Version built into the app (overridable in tests).
  final String policyVersion;
  final String aiConsentVersion;

  /// New `consentId` (UUID v4) – generated once per decision so retries stay idempotent.
  String newConsentId() => _newId();

  // ---------------------------------------------------------------- EK-02

  /// "Sign in" tapped with the box checked: write the temporary acceptance (no UID).
  Future<void> stagePolicyAcceptance({
    required String consentId,
    required String lang,
  }) => _pending.write(
    PendingPolicyAcceptance(
      consentId: consentId,
      version: policyVersion,
      lang: lang,
      acceptedAt: _now().toUtc(),
    ),
  );

  /// Sign-in failed or was cancelled: the temporary entry must not survive (CMP-09).
  Future<void> discardStagedPolicy() => _pending.clear();

  /// After a successful sign-in in EK-02: the staged acceptance becomes a local record
  /// of THIS account (unsynced). The staged entry stays until `recordConsent` succeeds
  /// (ADR-0005 Aneks A pkt 4). Called only from the sign-in flow, so an entry staged by
  /// someone else is never attached to a different account.
  Future<void> adoptStagedPolicy(String uid) async {
    final staged = await _pending.read();
    if (staged == null) return;
    await _local.upsert(uid, staged.toRecord());
  }

  // ---------------------------------------------------------------- EK-01

  /// EK-01: the app's policy version is newer than the latest local acceptance
  /// (or there is none) -> EK-03. Local and offline (ADR-0011 pkt 1).
  Future<bool> needsPolicyReconsent(String uid) async {
    final latest = await _local.latest(uid, ConsentType.privacyPolicy);
    if (latest == null || !latest.granted) return true;
    final have = AppConstants.versionNumber(latest.policyVersion);
    final want = AppConstants.versionNumber(policyVersion)!;
    return have == null || have < want;
  }

  // ---------------------------------------------------------------- sync

  /// Sends unsynced local records, oldest first (start, before EK-06 and before
  /// `generatePlan`). Stops at the first failure; never throws.
  Future<SyncOutcome> syncPending(String uid) async {
    final pending = (await _local.all(uid)).where((r) => !r.synced).toList();
    var synced = 0;
    for (final r in pending) {
      try {
        final receivedAt = await _api.recordConsent(r);
        await _local.upsert(uid, r.markSynced(receivedAt));
        await _clearStagedIfSame(r.id);
        synced++;
      } on AppFailure catch (f) {
        return SyncOutcome(
          synced: synced,
          remaining: pending.length - synced,
          failure: f,
        );
      } catch (_) {
        return SyncOutcome(
          synced: synced,
          remaining: pending.length - synced,
          failure: const AppFailure(FailureKind.generic),
        );
      }
    }
    return SyncOutcome(synced: synced, remaining: 0);
  }

  Future<void> _clearStagedIfSame(String consentId) async {
    final staged = await _pending.read();
    if (staged?.consentId == consentId) await _pending.clear();
  }

  // ---------------------------------------------------------------- EK-03

  /// EK-03 "Accept and continue": needs the network (U2). The record is stored locally
  /// only after the server confirmed it, so a failed attempt never unlocks the app.
  /// Pass the same [consentId] when retrying.
  Future<void> acceptPolicy({
    required String uid,
    required String consentId,
    required String lang,
  }) async {
    final record = ConsentRecord(
      id: consentId,
      type: ConsentType.privacyPolicy,
      granted: true,
      policyVersion: policyVersion,
      lang: lang,
      clientAt: _now().toUtc(),
    );
    final receivedAt = await _api.recordConsent(record);
    await _local.upsert(uid, record.markSynced(receivedAt));
  }

  // ---------------------------------------------------------------- EK-06

  /// EK-06 decision. Pending records are sent first (ADR-0011 pkt 10); then the AI
  /// record. Nothing is stored locally unless the server confirmed it ("nothing was
  /// sent" on error). Only "I agree" calls this: refusing at the first question
  /// creates no record (U-5); `granted=false` is for withdrawing in EK-13 (P3-05+).
  Future<void> recordAiDecision({
    required String uid,
    required String consentId,
    required bool granted,
    required String lang,
  }) async {
    final outcome = await syncPending(uid);
    final failure = outcome.failure;
    if (failure != null) throw failure;
    final record = ConsentRecord(
      id: consentId,
      type: ConsentType.aiProcessing,
      granted: granted,
      policyVersion: aiConsentVersion,
      lang: lang,
      clientAt: _now().toUtc(),
    );
    final receivedAt = await _api.recordConsent(record);
    await _local.upsert(uid, record.markSynced(receivedAt));
  }

  /// Current AI consent (local).
  Future<AiConsentState> aiConsentState(String uid) async {
    final latest = await _local.latest(uid, ConsentType.aiProcessing);
    if (latest == null) return AiConsentState.notGiven;
    if (!latest.granted) return AiConsentState.withdrawn;
    final have = AppConstants.versionNumber(latest.policyVersion);
    final want = AppConstants.versionNumber(aiConsentVersion)!;
    return have != null && have >= want
        ? AiConsentState.granted
        : AiConsentState.notGiven;
  }

  // ---------------------------------------------------------------- EK-16

  /// `consent_required` with [type]: if the latest record of that type is granted, synced
  /// and in the version built into the app, the server needs a newer app -> update;
  /// otherwise (none, unsynced, withdrawn, older) ask again (EK-03 / EK-06 with the
  /// "updated" intro).
  Future<ConsentRequiredAction> resolveConsentRequired(
    String uid,
    ConsentType type,
  ) async {
    final appVersion = type == ConsentType.privacyPolicy
        ? policyVersion
        : aiConsentVersion;
    final latest = await _local.latest(uid, type);
    final syncedInAppVersion =
        latest != null &&
        latest.synced &&
        latest.granted &&
        latest.policyVersion == appVersion;
    return syncedInAppVersion
        ? ConsentRequiredAction.updateApp
        : ConsentRequiredAction.askAgain;
  }
}
