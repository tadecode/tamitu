import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/application/consent_service.dart';
import 'package:tamitu/features/consent/domain/consent_ports.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';

import '../../helpers.dart';

void main() {
  const uid = 'u1';
  late TestEnv env;
  setUp(() => env = TestEnv());

  group('EK-02 staged policy acceptance (ADR-0005, ADR-0011 pkt 10)', () {
    test(
      'stage writes version, lang, acceptedAt and consentId - no UID',
      () async {
        await env.consents.stagePolicyAcceptance(consentId: 'c-1', lang: 'en');
        final p = env.pending.value!;
        expect(p.consentId, 'c-1');
        expect(p.version, AppConstants.privacyPolicyVersion);
        expect(p.lang, 'en');
        expect(p.acceptedAt, DateTime.utc(2026, 11, 17, 10));
      },
    );

    test(
      'discard removes the staged entry (failed / cancelled sign-in)',
      () async {
        await env.consents.stagePolicyAcceptance(consentId: 'c-1', lang: 'pl');
        await env.consents.discardStagedPolicy();
        expect(env.pending.value, isNull);
      },
    );

    test('adopt -> local unsynced record; sync -> server once, staged entry removed', () async {
      await env.consents.stagePolicyAcceptance(consentId: 'c-1', lang: 'pl');
      await env.consents.adoptStagedPolicy(uid);
      expect(await env.consents.needsPolicyReconsent(uid), isFalse);
      final before = (await env.local.all(uid)).single;
      expect(before.synced, isFalse);
      expect(
        env.pending.value,
        isNotNull,
        reason: 'kept until recordConsent succeeds',
      );

      final out = await env.consents.syncPending(uid);
      expect(out.complete, isTrue);
      expect(env.api.stored.keys, ['c-1']);
      final after = (await env.local.all(uid)).single;
      expect(after.synced, isTrue);
      expect(after.receivedAt, DateTime.utc(2026, 11, 17, 10));
      expect(env.pending.value, isNull, reason: 'ADR-0005 Aneks A pkt 4');
    });

    test(
      'sync failure keeps the record and the staged entry; retry is idempotent',
      () async {
        await env.consents.stagePolicyAcceptance(consentId: 'c-1', lang: 'pl');
        await env.consents.adoptStagedPolicy(uid);
        env.api.failures.add(const AppFailure(FailureKind.offline));
        final first = await env.consents.syncPending(uid);
        expect(first.failure?.kind, FailureKind.offline);
        expect(first.remaining, 1);
        expect(env.pending.value, isNotNull);
        // Retry: the record is sent once more; afterwards it is synced and not resent.
        await env.consents.syncPending(uid);
        await env.consents.syncPending(uid);
        expect(env.api.stored.length, 1);
        expect(env.api.calls, 2, reason: 'synced record is not sent again');
      },
    );

    test('adopt without a staged entry does nothing', () async {
      await env.consents.adoptStagedPolicy(uid);
      expect(await env.local.all(uid), isEmpty);
    });
  });

  group('EK-01 policy version check (ADR-0011 pkt 1, local and offline)', () {
    test(
      'no record / withdrawn / older version -> reconsent; same or newer -> ok',
      () async {
        expect(await env.consents.needsPolicyReconsent(uid), isTrue);
        Future<void> put(
          String id,
          String v, {
          bool granted = true,
          int day = 1,
        }) => env.local.upsert(
          uid,
          ConsentRecord(
            id: id,
            type: ConsentType.privacyPolicy,
            granted: granted,
            policyVersion: v,
            lang: 'pl',
            clientAt: DateTime.utc(2026, 11, day),
          ),
        );
        final v2 = TestEnv().consents; // app with privacy-v2 below
        final svc = ConsentService(
          local: env.local,
          pending: env.pending,
          api: env.api,
          newId: idSequence(),
          policyVersion: 'privacy-v2',
        );
        await put('a', 'privacy-v1');
        expect(await env.consents.needsPolicyReconsent(uid), isFalse);
        expect(
          await svc.needsPolicyReconsent(uid),
          isTrue,
          reason: 'app has a newer policy',
        );
        await put('b', 'privacy-v3', day: 2);
        expect(
          await svc.needsPolicyReconsent(uid),
          isFalse,
          reason: 'N >= app N',
        );
        await put('c', 'privacy-v3', granted: false, day: 3);
        expect(await svc.needsPolicyReconsent(uid), isTrue);
        expect(
          await v2.needsPolicyReconsent(uid),
          isTrue,
          reason: 'other account isolated',
        );
      },
    );

    test('accounts are isolated (N3)', () async {
      await env.acceptCurrentPolicy('a');
      expect(await env.consents.needsPolicyReconsent('a'), isFalse);
      expect(await env.consents.needsPolicyReconsent('b'), isTrue);
    });
  });

  group('EK-03 acceptPolicy (U2: needs the network)', () {
    test('success stores a synced record with the server time', () async {
      await env.consents.acceptPolicy(uid: uid, consentId: 'r-1', lang: 'en');
      final r = (await env.local.all(uid)).single;
      expect(r.synced, isTrue);
      expect(r.lang, 'en');
      expect(r.policyVersion, AppConstants.privacyPolicyVersion);
      expect(await env.consents.needsPolicyReconsent(uid), isFalse);
    });

    test('offline: nothing stored locally, the app stays locked', () async {
      env.api.failures.add(const AppFailure(FailureKind.offline));
      await expectLater(
        env.consents.acceptPolicy(uid: uid, consentId: 'r-1', lang: 'pl'),
        throwsA(
          isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.offline),
        ),
      );
      expect(await env.local.all(uid), isEmpty);
      expect(await env.consents.needsPolicyReconsent(uid), isTrue);
    });
  });

  group('EK-06 recordAiDecision', () {
    test(
      'sends pending records first, then the AI record (ADR-0011 pkt 10)',
      () async {
        await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
        await env.consents.adoptStagedPolicy(uid);
        final order = <String>[];
        final api = _RecordingApi(order);
        final svc = ConsentService(
          local: env.local,
          pending: env.pending,
          api: api,
          newId: idSequence(),
        );
        await svc.recordAiDecision(
          uid: uid,
          consentId: 'a-1',
          granted: true,
          lang: 'pl',
        );
        expect(order, ['privacy_policy:p-1', 'ai_processing:a-1']);
        expect(await svc.aiConsentState(uid), AiConsentState.granted);
      },
    );

    test(
      'failure of a pending record: AI record not sent, nothing stored',
      () async {
        await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
        await env.consents.adoptStagedPolicy(uid);
        env.api.failures.add(const AppFailure(FailureKind.offline));
        await expectLater(
          env.consents.recordAiDecision(
            uid: uid,
            consentId: 'a-1',
            granted: true,
            lang: 'pl',
          ),
          throwsA(isA<AppFailure>()),
        );
        expect(env.api.stored.containsKey('a-1'), isFalse);
        expect(await env.consents.aiConsentState(uid), AiConsentState.notGiven);
      },
    );

    test(
      'AI state: none -> notGiven, withdrawn, older version -> notGiven',
      () async {
        expect(await env.consents.aiConsentState(uid), AiConsentState.notGiven);
        await env.consents.recordAiDecision(
          uid: uid,
          consentId: 'a-1',
          granted: false,
          lang: 'pl',
        );
        expect(
          await env.consents.aiConsentState(uid),
          AiConsentState.withdrawn,
        );
        // Granted later in ai-consent-v1 (this app's version).
        final later = ConsentService(
          local: env.local,
          pending: env.pending,
          api: env.api,
          newId: idSequence(),
          now: () => DateTime.utc(2026, 11, 18),
        );
        await later.recordAiDecision(
          uid: uid,
          consentId: 'a-2',
          granted: true,
          lang: 'pl',
        );
        expect(await later.aiConsentState(uid), AiConsentState.granted);
        // An app with ai-consent-v2 treats the v1 grant as not given (EK-06 again).
        final v2 = ConsentService(
          local: env.local,
          pending: env.pending,
          api: env.api,
          newId: idSequence(),
          aiConsentVersion: 'ai-consent-v2',
        );
        expect(await v2.aiConsentState(uid), AiConsentState.notGiven);
      },
    );
  });

  group('EK-16 consent_required (ADR-0011 pkt 7, ADR-0012 pkt 5)', () {
    test(
      'no or unsynced record -> ask again; synced in app version -> update app',
      () async {
        expect(
          await env.consents.resolveConsentRequired(
            uid,
            ConsentType.privacyPolicy,
          ),
          ConsentRequiredAction.askAgain,
        );
        await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
        await env.consents.adoptStagedPolicy(uid);
        expect(
          await env.consents.resolveConsentRequired(
            uid,
            ConsentType.privacyPolicy,
          ),
          ConsentRequiredAction.askAgain,
          reason: 'unsynced: sending it may fix the server state',
        );
        await env.consents.syncPending(uid);
        expect(
          await env.consents.resolveConsentRequired(
            uid,
            ConsentType.privacyPolicy,
          ),
          ConsentRequiredAction.updateApp,
        );
      },
    );

    test(
      'AI: synced grant -> update app; after withdrawal -> ask again',
      () async {
        await env.consents.recordAiDecision(
          uid: uid,
          consentId: 'a-1',
          granted: true,
          lang: 'pl',
        );
        expect(
          await env.consents.resolveConsentRequired(
            uid,
            ConsentType.aiProcessing,
          ),
          ConsentRequiredAction.updateApp,
        );
        final later = ConsentService(
          local: env.local,
          pending: env.pending,
          api: env.api,
          newId: idSequence(),
          now: () => DateTime.utc(2026, 11, 18),
        );
        await later.recordAiDecision(
          uid: uid,
          consentId: 'a-2',
          granted: false,
          lang: 'pl',
        );
        expect(
          await later.resolveConsentRequired(uid, ConsentType.aiProcessing),
          ConsentRequiredAction.askAgain,
        );
      },
    );
  });
}

class _RecordingApi implements ConsentApi {
  _RecordingApi(this.order);

  final List<String> order;

  @override
  Future<DateTime> recordConsent(ConsentRecord record) async {
    order.add('${record.type.wire}:${record.id}');
    return DateTime.utc(2026, 11, 17);
  }
}
