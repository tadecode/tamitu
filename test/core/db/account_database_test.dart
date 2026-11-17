import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/db/account_database.dart';
import 'package:tamitu/core/db/account_databases.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/data/sqlite_consent_local_store.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';

/// Test-only database key (not a secret): 32 bytes 0x00..0x1f as 64 hex chars, built at
/// runtime so no key-like literal sits in the repository (gitleaks generic-api-key).
final keyA = List.generate(
  32,
  (i) => i.toRadixString(16).padLeft(2, '0'),
).join();

ConsentRecord rec(String id, {bool synced = false, int minute = 0}) =>
    ConsentRecord(
      id: id,
      type: ConsentType.privacyPolicy,
      granted: true,
      policyVersion: 'privacy-v1',
      lang: 'pl',
      clientAt: DateTime.utc(2026, 11, 17, 10, minute),
      receivedAt: synced ? DateTime.utc(2026, 11, 17, 10, minute, 1) : null,
      synced: synced,
    );

void main() {
  late Directory dir;
  late MemoryDbKeyStore keys;
  final opened = <AccountDatabases>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tamitu_db_test');
    keys = MemoryDbKeyStore();
  });
  tearDown(() async {
    for (final d in opened) {
      await d.closeAll();
    }
    opened.clear();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AccountDatabases dbs() {
    final d = AccountDatabases(directory: () async => dir, keys: keys);
    opened.add(d);
    return d;
  }

  test(
    'SQLCipher is linked (hook source: sqlcipher) and the file is encrypted',
    () async {
      final file = File('${dir.path}/x.db');
      final db = await openAccountDatabase(file, hexKey: keyA);
      await db.customStatement('CREATE TABLE IF NOT EXISTS t (v TEXT)');
      await db.customStatement("INSERT INTO t VALUES ('plain-marker')");
      await db.close();
      final bytes = await file.readAsBytes();
      expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
      expect(String.fromCharCodes(bytes), isNot(contains('plain-marker')));
    },
  );

  test(
    'restart: records written by one instance are read by a new one (BUG-1)',
    () async {
      final first = dbs();
      final store1 = SqliteConsentLocalStore(first);
      await store1.upsert('u1', rec('c-1', synced: true));
      await store1.upsert('u1', rec('c-2', minute: 1));
      await first.closeAll();

      // New process: new AccountDatabases and store over the same directory and key.
      final store2 = SqliteConsentLocalStore(dbs());
      final all = await store2.all('u1');
      expect(all.map((r) => r.id), ['c-1', 'c-2']);
      expect(all.first.synced, isTrue);
      expect(all.first.receivedAt, DateTime.utc(2026, 11, 17, 10, 0, 1));
      expect(all.last.synced, isFalse);
      expect(all.last.receivedAt, isNull);
      expect((await store2.latest('u1', ConsentType.privacyPolicy))?.id, 'c-2');
      expect(await store2.takeDataReset('u1'), isFalse);
    },
  );

  test('one file per account; file name does not contain the UID', () async {
    final store = SqliteConsentLocalStore(dbs());
    await store.upsert('alice-uid', rec('a'));
    await store.upsert('bob-uid', rec('b'));
    expect((await store.all('alice-uid')).map((r) => r.id), ['a']);
    expect((await store.all('bob-uid')).map((r) => r.id), ['b']);
    final names = dir.listSync().map((e) => e.uri.pathSegments.last).toList();
    expect(
      names,
      containsAll([
        accountDbFileName('alice-uid'),
        accountDbFileName('bob-uid'),
      ]),
    );
    expect(names.join(), isNot(contains('alice')));
    expect(
      accountDbFileName('u'),
      matches(RegExp(r'^tamitu_[0-9a-f]{16}\.db$')),
    );
  });

  test(
    'lost key: unreadable file deleted, empty database, reset reported once',
    () async {
      final first = dbs();
      await SqliteConsentLocalStore(first)
          .upsert('u1', rec('c-1', synced: true));
      await first.closeAll();
      keys.value = null; // Keystore lost the key (ADR-0005 Aneks A pkt 2)

      final store = SqliteConsentLocalStore(dbs());
      expect(await store.all('u1'), isEmpty);
      expect(await store.takeDataReset('u1'), isTrue);
      expect(await store.takeDataReset('u1'), isFalse);
    },
  );

  test('a brand-new account database is not a "reset"', () async {
    final store = SqliteConsentLocalStore(dbs());
    expect(await store.takeDataReset('new'), isFalse);
  });

  test('schema v1: consents_local with received_at, schema_meta = 1', () async {
    final db = (await dbs().open('u1')).db;
    final cols = await db
        .customSelect('PRAGMA table_info(consents_local)')
        .get();
    expect(
      cols.map((c) => c.read<String>('name')),
      containsAll([
        'id',
        'type',
        'granted',
        'policy_version',
        'lang',
        'client_at',
        'received_at',
        'synced',
      ]),
    );
    final meta = await db
        .customSelect('SELECT version FROM schema_meta')
        .getSingle();
    expect(meta.read<int>('version'), AccountDatabase.currentSchemaVersion);
    final uv = await db.customSelect('PRAGMA user_version').getSingle();
    expect(uv.data.values.first, AccountDatabase.currentSchemaVersion);
    expect(
      AccountDatabase.migrations.length,
      AccountDatabase.currentSchemaVersion,
    );
  });

  test('upsert by id replaces (sync marks the same record)', () async {
    final store = SqliteConsentLocalStore(dbs());
    await store.upsert('u1', rec('c-1'));
    await store.upsert(
      'u1',
      rec('c-1').markSynced(DateTime.utc(2026, 11, 17, 11)),
    );
    final all = await store.all('u1');
    expect(all, hasLength(1));
    expect(all.single.synced, isTrue);
  });
}
