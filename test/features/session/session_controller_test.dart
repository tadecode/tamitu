import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/app/providers.dart';
import 'package:tamitu/app/router.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/session/session_controller.dart';

import '../../helpers.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('sessionRedirect (EK-01 gate)', () {
    test(
      'loading -> start; signed out -> welcome; needs policy -> reconsent',
      () {
        expect(sessionRedirect(const SessionLoading(), '/home'), Routes.start);
        expect(sessionRedirect(const SessionLoading(), Routes.start), isNull);
        expect(
          sessionRedirect(const SessionSignedOut(), '/home'),
          Routes.welcome,
        );
        expect(
          sessionRedirect(const SessionSignedOut(), '/ai-consent'),
          Routes.welcome,
        );
        expect(
          sessionRedirect(const SessionNeedsPolicy('u'), '/home'),
          Routes.reconsent,
        );
        expect(
          sessionRedirect(const SessionNeedsPolicy('u'), '/ai-consent'),
          Routes.reconsent,
        );
      },
    );

    test('ready leaves gate routes for home and keeps other routes', () {
      for (final r in [Routes.start, Routes.welcome, Routes.reconsent]) {
        expect(sessionRedirect(const SessionReady('u'), r), Routes.home);
      }
      expect(sessionRedirect(const SessionReady('u'), Routes.home), isNull);
      expect(
        sessionRedirect(const SessionReady('u'), Routes.aiConsent),
        isNull,
      );
    });
  });

  group('SessionController', () {
    test('no session -> signed out', () async {
      final env = TestEnv();
      final c = env.container();
      expect(c.read(sessionProvider), isA<SessionLoading>());
      await settle();
      expect(c.read(sessionProvider), isA<SessionSignedOut>());
    });

    test(
      'restored session (offline) with current acceptance -> ready (US-001)',
      () async {
        final env = TestEnv(user: const AuthUser('u1'));
        await env.acceptCurrentPolicy('u1');
        final c = env.container();
        c.read(sessionProvider);
        await settle();
        await settle();
        expect(c.read(sessionProvider), isA<SessionReady>());
      },
    );

    test('restored session without local acceptance -> EK-03', () async {
      final env = TestEnv(user: const AuthUser('u1'));
      final c = env.container();
      c.read(sessionProvider);
      await settle();
      await settle();
      expect(c.read(sessionProvider), isA<SessionNeedsPolicy>());
    });

    test(
      'sign-in adopts the staged acceptance: ready, never EK-03, then synced',
      () async {
        final env = TestEnv();
        final c = env.container();
        final seen = <SessionStatus>[];
        c.listen(sessionProvider, (_, s) => seen.add(s), fireImmediately: true);
        await settle();
        await c
            .read(sessionProvider.notifier)
            .signInWithGoogle(consentId: 'c-1', lang: 'pl');
        await settle();
        expect(c.read(sessionProvider), isA<SessionReady>());
        expect(seen.whereType<SessionNeedsPolicy>(), isEmpty);
        expect(env.api.stored.keys, [
          'c-1',
        ], reason: 'recordConsent after sign-in');
        expect(
          env.pending.value,
          isNull,
          reason: 'staged entry removed after success',
        );
      },
    );

    test('offline recordConsent after sign-in does not block EK-04 (ADR-0011 pkt 10)', () async {
      final env = TestEnv();
      env.api.failures.add(const AppFailure(FailureKind.offline));
      final c = env.container();
      c.read(sessionProvider);
      await settle();
      await c
          .read(sessionProvider.notifier)
          .signInWithGoogle(consentId: 'c-1', lang: 'en');
      await settle();
      expect(c.read(sessionProvider), isA<SessionReady>());
      expect(
        env.pending.value?.consentId,
        'c-1',
        reason: 'kept for the next retry',
      );
    });

    test('cancelled sign-in: failure rethrown, staged entry cleared, still signed out', () async {
      final env = TestEnv();
      env.auth.nextSignInFailure = const AppFailure(FailureKind.cancelled);
      final c = env.container();
      c.read(sessionProvider);
      await settle();
      await expectLater(
        c
            .read(sessionProvider.notifier)
            .signInWithGoogle(consentId: 'c-1', lang: 'pl'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.kind,
            'kind',
            FailureKind.cancelled,
          ),
        ),
      );
      expect(env.pending.value, isNull);
      expect(c.read(sessionProvider), isA<SessionSignedOut>());
    });

    test('sign out -> signed out (US-002)', () async {
      final env = TestEnv(user: const AuthUser('u1'));
      await env.acceptCurrentPolicy('u1');
      final c = env.container();
      c.read(sessionProvider);
      await settle();
      await c.read(sessionProvider.notifier).signOut();
      expect(c.read(sessionProvider), isA<SessionSignedOut>());
      expect(env.auth.signOutCalls, 1);
    });

    test('unauthenticated during background sync -> signed out with a flash (EK-16)', () async {
      final env = TestEnv(user: const AuthUser('u1'));
      await env.consents.stagePolicyAcceptance(consentId: 'c-1', lang: 'pl');
      await env.consents.adoptStagedPolicy('u1');
      env.api.failures.add(const AppFailure(FailureKind.unauthenticated));
      final c = env.container();
      c.read(sessionProvider);
      for (var i = 0; i < 5; i++) {
        await settle();
      }
      expect(c.read(sessionProvider), isA<SessionSignedOut>());
      expect(c.read(welcomeFlashProvider), WelcomeFlash.sessionExpired);
    });
  });
}
