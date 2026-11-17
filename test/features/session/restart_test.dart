import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/app/providers.dart';
import 'package:tamitu/core/db/account_databases.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/data/fake_auth_gateway.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/consent/application/consent_service.dart';
import 'package:tamitu/features/consent/data/fake_consent_api.dart';
import 'package:tamitu/features/consent/data/prefs_pending_policy_store.dart';
import 'package:tamitu/features/consent/data/sqlite_consent_local_store.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';
import 'package:tamitu/features/session/session_controller.dart';

import '../../helpers.dart';

/// What survives a process restart: the database directory + key (Keystore), the
/// `shared_preferences` entry and the server. Everything else is rebuilt per "process".
class Device {
  Device(this.dir);

  final Directory dir;
  final keys = MemoryDbKeyStore();
  final prefs = MemoryPendingPolicyStore();
  final server = FakeConsentApi(now: () => DateTime.utc(2026, 11, 17, 10));
  final _open = <AccountDatabases>[];

  /// One app process: fresh database handles, service and session controller.
  ProviderContainer start({AuthUser? session}) {
    final dbs = AccountDatabases(directory: () async => dir, keys: keys);
    _open.add(dbs);
    final consents = ConsentService(
      local: SqliteConsentLocalStore(dbs),
      pending: prefs,
      api: server,
      newId: idSequence(),
      now: () => DateTime.utc(2026, 11, 17, 10),
    );
    final c = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(
          FakeAuthGateway(initialUser: session, nextUser: const AuthUser('u1')),
        ),
        consentServiceProvider.overrideWithValue(consents),
      ],
    );
    c.read(sessionProvider);
    return c;
  }

  Future<void> killAll() async {
    for (final d in _open) {
      await d.closeAll();
    }
    _open.clear();
  }
}

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Device device;
  setUp(() async {
    device = Device(await Directory.systemTemp.createTemp('tamitu_restart'));
  });
  tearDown(() async {
    await device.killAll();
    await device.dir.delete(recursive: true);
  });

  test('BUG-1: after a restart OFFLINE with a stored acceptance -> EK-04 (US-001 AC4), '
      'and no new privacy_policy record is created', () async {
    final p1 = device.start();
    await settle();
    await p1
        .read(sessionProvider.notifier)
        .signInWithGoogle(consentId: 'c-1', lang: 'pl');
    await settle();
    expect(p1.read(sessionProvider), isA<SessionReady>());
    expect(device.server.stored.keys, ['c-1']);
    p1.dispose();
    await device.killAll();

    device.server.failures.addAll(
      List.filled(5, const AppFailure(FailureKind.offline)),
    );
    final p2 = device.start(session: const AuthUser('u1'));
    await settle();
    expect(p2.read(sessionProvider), isA<SessionReady>());
    expect(device.server.stored.length, 1, reason: 'no new record per restart');
    expect(device.server.calls, 1, reason: 'synced record is not resent');
    p2.dispose();
  });

  test('BUG-2: sync failed, app killed -> next start with network sends it once and '
      'clears the staged entry (ADR-0011 pkt 10)', () async {
    device.server.failures.add(const AppFailure(FailureKind.offline));
    final p1 = device.start();
    await settle();
    await p1
        .read(sessionProvider.notifier)
        .signInWithGoogle(consentId: 'c-1', lang: 'en');
    await settle();
    expect(p1.read(sessionProvider), isA<SessionReady>());
    expect(device.server.stored, isEmpty);
    expect(device.prefs.value?.consentId, 'c-1');
    p1.dispose();
    await device.killAll();

    final p2 = device.start(session: const AuthUser('u1'));
    await settle();
    expect(p2.read(sessionProvider), isA<SessionReady>());
    expect(device.server.stored.keys, ['c-1']);
    expect(device.server.stored['c-1']!.record.lang, 'en');
    expect(device.prefs.value, isNull);
    p2.dispose();
  });

  test('BUG-2: killed between Google sign-in and adoption -> adopted at next start', () async {
    // The staged entry exists, the session exists, but no local record was written.
    await device.prefs.write(PendingPolicyAcceptanceFixture.make('c-9'));
    final p = device.start(session: const AuthUser('u1'));
    await settle();
    expect(p.read(sessionProvider), isA<SessionReady>(), reason: 'not EK-03');
    expect(device.server.stored.keys, ['c-9']);
    expect(device.prefs.value, isNull);
    p.dispose();
  });

  test(
    'sign-out drops a staged entry: it never reaches the next account (QA5)',
    () async {
      device.server.failures.add(const AppFailure(FailureKind.offline));
      final p1 = device.start();
      await settle();
      await p1
          .read(sessionProvider.notifier)
          .signInWithGoogle(consentId: 'c-1', lang: 'pl');
      await settle();
      await p1.read(sessionProvider.notifier).signOut();
      expect(device.prefs.value, isNull);
      p1.dispose();
      await device.killAll();

      final p2 = device.start(session: const AuthUser('other'));
      await settle();
      expect(p2.read(sessionProvider), isA<SessionNeedsPolicy>());
      expect(
        device.server.stored.values.where((s) => s.record.id == 'c-1'),
        isEmpty,
      );
      p2.dispose();
      // u1's unsynced record is still in u1's database and is sent at u1's next start.
      await device.killAll();
      final p3 = device.start(session: const AuthUser('u1'));
      await settle();
      expect(device.server.stored.keys, contains('c-1'));
      p3.dispose();
    },
  );

  test('lost database key -> EK-03 in the data-reset variant', () async {
    final p1 = device.start();
    await settle();
    await p1
        .read(sessionProvider.notifier)
        .signInWithGoogle(consentId: 'c-1', lang: 'pl');
    await settle();
    p1.dispose();
    await device.killAll();
    device.keys.value = null;

    final p2 = device.start(session: const AuthUser('u1'));
    await settle();
    final s = p2.read(sessionProvider);
    expect(s, isA<SessionNeedsPolicy>());
    expect((s as SessionNeedsPolicy).dataReset, isTrue);
    p2.dispose();
  });
}

abstract final class PendingPolicyAcceptanceFixture {
  static PendingPolicyAcceptance make(String id) => PendingPolicyAcceptance(
    consentId: id,
    version: 'privacy-v1',
    lang: 'pl',
    acceptedAt: DateTime.utc(2026, 11, 17, 9),
  );
}
