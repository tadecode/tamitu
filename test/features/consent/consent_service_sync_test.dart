import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/errors/app_failure.dart';

import '../../helpers.dart';

void main() {
  const uid = 'u1';

  test('one sync in flight per account: concurrent callers share it (review #5, CONS-05)', () async {
    final env = TestEnv();
    await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
    await env.consents.adoptStagedPolicy(uid);
    env.api.gate = Completer<void>();
    final a = env.consents.syncPending(uid); // background sync after start
    final b = env.consents.syncPending(
      uid,
    ); // "I agree" in EK-06 at the same time
    env.api.gate!.complete();
    final results = await Future.wait([a, b]);
    expect(env.api.calls, 1, reason: 'the record is sent once');
    expect(results.every((r) => r.complete), isTrue);
    // After it finished, a new sync may run again.
    await env.consents.syncPending(uid);
    expect(env.api.calls, 1, reason: 'nothing left to send');
  });

  test('EK-06 waits for the running sync, then sends the AI record', () async {
    final env = TestEnv();
    await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
    await env.consents.adoptStagedPolicy(uid);
    env.api.gate = Completer<void>();
    final bg = env.consents.syncPending(uid);
    final ai = env.consents.recordAiDecision(
      uid: uid,
      consentId: 'a-1',
      granted: true,
      lang: 'pl',
    );
    env.api.gate!.complete();
    await bg;
    await ai;
    expect(env.api.stored.keys, ['p-1', 'a-1']);
    expect(env.api.calls, 2);
  });

  test(
    'adopt never duplicates or overwrites a stored record with the same id',
    () async {
      final env = TestEnv();
      await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
      await env.consents.adoptStagedPolicy(uid);
      env.api.failures.add(const AppFailure(FailureKind.offline));
      await env.consents.syncPending(uid);
      await env.consents.syncPending(uid); // synced now; staged entry cleared
      await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'en');
      await env.consents.adoptStagedPolicy(uid);
      final all = await env.local.all(uid);
      expect(all, hasLength(1));
      expect(all.single.synced, isTrue, reason: 'synced record kept');
      expect(all.single.lang, 'pl');
    },
  );

  test(
    'onSessionStart adopts a staged entry and reports data reset once',
    () async {
      final env = TestEnv();
      await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
      env.local.resetFor.add(uid);
      final s1 = await env.consents.onSessionStart(uid);
      expect(s1.needsPolicy, isFalse);
      expect(s1.dataReset, isTrue);
      final s2 = await env.consents.onSessionStart(uid);
      expect(s2.dataReset, isFalse);
    },
  );

  test('onSignOut clears the staged entry and closes the databases', () async {
    final env = TestEnv();
    await env.consents.stagePolicyAcceptance(consentId: 'p-1', lang: 'pl');
    await env.consents.onSignOut();
    expect(env.pending.value, isNull);
    expect(env.local.closeAllCalls, 1);
  });
}
