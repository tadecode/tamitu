import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Encrypted per-account database (ADR-0005 pkt 1, docs/data/model-danych.md pkt 2.2).
///
/// P3-04 ships the core only: file per account, SQLCipher key, versioned migrations and
/// `consents_local`. Plan tables (`trips`, `plan_days`, `plan_items`) come with P3-06 as
/// migration v2. Drift is used without code generation (raw SQL), so P3-06 can switch to
/// generated tables on the same file.
class AccountDatabase extends GeneratedDatabase {
  AccountDatabase(super.executor);

  /// Bump together with a new step in [migrations].
  static const currentSchemaVersion = 1;

  /// Migration steps: index i migrates from version i to i + 1.
  static const migrations = <List<String>>[
    // v0 -> v1 (P3-04): consents_local (+ received_at, UX17) and schema_meta.
    [
      '''
      CREATE TABLE consents_local (
        id             TEXT PRIMARY KEY NOT NULL,
        type           TEXT NOT NULL,
        granted        INTEGER NOT NULL,
        policy_version TEXT NOT NULL,
        lang           TEXT NOT NULL,
        client_at      INTEGER NOT NULL,
        received_at    INTEGER NULL,
        synced         INTEGER NOT NULL DEFAULT 0
      )
      ''',
      'CREATE INDEX consents_local_type_client_at ON consents_local (type, client_at)',
      'CREATE TABLE schema_meta (version INTEGER NOT NULL)',
      'INSERT INTO schema_meta (version) VALUES (1)',
    ],
  ];

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => _migrate(0, currentSchemaVersion),
    onUpgrade: (m, from, to) => _migrate(from, to),
  );

  Future<void> _migrate(int from, int to) async {
    for (var v = from; v < to; v++) {
      for (final sql in migrations[v]) {
        await customStatement(sql);
      }
      if (v > 0) {
        await customStatement('UPDATE schema_meta SET version = ?', [v + 1]);
      }
    }
  }
}

/// `tamitu_<sha256(uid)[0..16]>.db` (ADR-0005 pkt 1). The UID itself is not in the name.
String accountDbFileName(String uid) =>
    'tamitu_${sha256.convert(uid.codeUnits).toString().substring(0, 16)}.db';

/// Thrown when the file cannot be decrypted with the current key (lost Keystore key,
/// corrupted file): ADR-0005 Aneks A pkt 2 - the caller deletes it and starts empty.
class UnreadableDatabase implements Exception {
  const UnreadableDatabase();

  @override
  String toString() => 'UnreadableDatabase';
}

/// Opens [file] with the SQLCipher [hexKey] (64 hex chars = 256 bit raw key) and
/// verifies that it can be read. [requireCipher]: fail if the linked SQLite has no
/// SQLCipher (release builds must never write the account database in plain text).
Future<AccountDatabase> openAccountDatabase(
  File file, {
  required String hexKey,
  bool requireCipher = true,
}) async {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hexKey)) {
    throw ArgumentError('key must be 64 lowercase hex characters');
  }
  final db = AccountDatabase(
    NativeDatabase(
      file,
      setup: (raw) {
        if (requireCipher) {
          final v = raw.select('PRAGMA cipher_version');
          if (v.isEmpty || '${v.first.values.first}'.isEmpty) {
            throw StateError('SQLCipher is not available');
          }
        }
        raw.execute("PRAGMA key = \"x'$hexKey'\"");
        // Fails with SQLITE_NOTADB when the key does not match.
        raw.select('SELECT count(*) FROM sqlite_master');
        raw.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
  try {
    await db.customSelect('SELECT 1').get();
    return db;
  } on SqliteException catch (e) {
    await db.close();
    // 26 = SQLITE_NOTADB (wrong key or not a database).
    if (e.resultCode == 26) throw const UnreadableDatabase();
    rethrow;
  } catch (_) {
    await db.close();
    rethrow;
  }
}

/// Deletes the database file and its side files (ADR-0005 Aneks A pkt 1: file deletion).
Future<void> deleteDatabaseFiles(File file) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${file.path}$suffix');
    if (await f.exists()) await f.delete();
  }
}
