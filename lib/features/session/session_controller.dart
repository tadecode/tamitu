import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/app_failure.dart';
import '../auth/domain/auth_gateway.dart';
import '../consent/application/consent_service.dart';

/// Where the session gate (EK-01) sends the user.
sealed class SessionStatus {
  const SessionStatus();
}

/// Deciding (splash / EK-01 indicator).
class SessionLoading extends SessionStatus {
  const SessionLoading();
}

/// No session -> EK-02.
class SessionSignedOut extends SessionStatus {
  const SessionSignedOut();
}

/// Policy built into the app is newer than the local acceptance -> EK-03.
class SessionNeedsPolicy extends SessionStatus {
  const SessionNeedsPolicy(this.uid, {this.dataReset = false});

  final String uid;

  /// EK-03 variant after the unreadable database was cleared (P3-06).
  final bool dataReset;
}

/// The account database could not be opened (not a lost key): error with retry.
class SessionStorageError extends SessionStatus {
  const SessionStorageError(this.uid);

  final String uid;
}

/// Signed in with a current acceptance -> EK-04.
class SessionReady extends SessionStatus {
  const SessionReady(this.uid);

  final String uid;
}

/// EK-01 logic (US-001, US-002, US-003; ADR-0004, ADR-0011 pkt 1 and 10).
///
/// Not in P3-04: unreadable database flow (P3-06) and interrupted account deletion
/// (P3-08); their states plug in here.
class SessionController extends Notifier<SessionStatus> {
  StreamSubscription<AuthUser?>? _sub;
  bool _signingIn = false;
  int _generation = 0;

  /// Keeps the EK-03 data-reset variant until the policy is accepted again.
  String? _dataResetFor;

  AuthGateway get _auth => ref.read(authGatewayProvider);
  ConsentService get _consents => ref.read(consentServiceProvider);

  @override
  SessionStatus build() {
    _sub = _auth.sessionChanges().listen((user) {
      // During sign-in the flow itself evaluates once the staged consent is adopted,
      // so the gate never flashes EK-03 in between.
      if (!_signingIn) unawaited(_evaluate(user));
    });
    ref.onDispose(() => _sub?.cancel());
    return const SessionLoading();
  }

  Future<void> _evaluate(AuthUser? user) async {
    final gen = ++_generation;
    if (user == null) {
      state = const SessionSignedOut();
      return;
    }
    final SessionConsentState consent;
    try {
      consent = await _consents.onSessionStart(user.uid);
    } catch (_) {
      // Account database cannot be opened for another reason than a lost key (e.g. no
      // space): retry, never delete data (EK-01, ADR-0011 pkt 9).
      if (ref.mounted && gen == _generation) {
        state = SessionStorageError(user.uid);
      }
      return;
    }
    if (!ref.mounted || gen != _generation) return;
    if (consent.dataReset) _dataResetFor = user.uid;
    if (!consent.needsPolicy && _dataResetFor == user.uid) _dataResetFor = null;
    state = consent.needsPolicy
        ? SessionNeedsPolicy(user.uid, dataReset: _dataResetFor == user.uid)
        : SessionReady(user.uid);
    // Retry unsynced consent records (ADR-0011 pkt 10); never blocks entering EK-04.
    unawaited(_syncInBackground(user.uid));
  }

  Future<void> _syncInBackground(String uid) async {
    final outcome = await _consents.syncPending(uid);
    if (!ref.mounted) return;
    if (outcome.failure?.kind == FailureKind.unauthenticated) {
      await expireSession();
    }
  }

  /// EK-02 "Sign in with Google" with the policy box checked. Throws `AppFailure`
  /// (cancelled / offline / generic); on any failure the staged acceptance is removed.
  Future<void> signInWithGoogle({
    required String consentId,
    required String lang,
  }) async {
    _signingIn = true;
    try {
      final AuthUser user;
      try {
        await _consents.stagePolicyAcceptance(consentId: consentId, lang: lang);
        user = await _auth.signInWithGoogle();
      } catch (e) {
        await _consents.discardStagedPolicy();
        if (e is AppFailure) rethrow;
        throw const AppFailure(FailureKind.generic);
      }
      // Signed in: adoption happens in onSessionStart (also after a crash here).
      _signingIn = false;
      await _evaluate(user);
    } finally {
      _signingIn = false;
    }
  }

  /// EK-03 accepted: re-evaluate (goes to EK-04).
  Future<void> refresh() => _evaluate(_auth.currentUser);

  /// Sign out (US-002). Plans stay on the device (P3-06).
  Future<void> signOut() async {
    await _auth.signOut();
    await _consents.onSignOut();
    await _evaluate(null);
  }

  /// `unauthenticated` from the server: back to EK-02 with `errorSessionExpired`.
  Future<void> expireSession() async {
    ref.read(welcomeFlashProvider.notifier).show(WelcomeFlash.sessionExpired);
    await signOut();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionStatus>(
  SessionController.new,
);
