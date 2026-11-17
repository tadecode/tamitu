import 'package:drift/drift.dart';

import '../../../core/db/account_databases.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/consent_ports.dart';
import '../domain/consent_record.dart';

/// `consents_local` in the encrypted account database (ADR-0005 pkt 3). Survives
/// restarts, so EK-01 works offline and unsynced records are retried at the next start.
class SqliteConsentLocalStore implements ConsentLocalStore {
  SqliteConsentLocalStore(this._dbs);

  final AccountDatabases _dbs;

  @override
  Future<void> upsert(String uid, ConsentRecord r) async {
    final db = (await _dbs.open(uid)).db;
    await db.customStatement(
      'INSERT OR REPLACE INTO consents_local '
      '(id, type, granted, policy_version, lang, client_at, received_at, synced) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        r.id,
        r.type.wire,
        r.granted ? 1 : 0,
        r.policyVersion,
        r.lang,
        r.clientAt.toUtc().millisecondsSinceEpoch,
        r.receivedAt?.toUtc().millisecondsSinceEpoch,
        r.synced ? 1 : 0,
      ],
    );
  }

  @override
  Future<List<ConsentRecord>> all(String uid) async {
    final db = (await _dbs.open(uid)).db;
    // rowid keeps insertion order for equal client_at (INSERT OR REPLACE = new rowid,
    // but the replaced record is the same decision).
    final rows = await db
        .customSelect('SELECT * FROM consents_local ORDER BY client_at, rowid')
        .get();
    return [for (final row in rows) ?_fromRow(row)];
  }

  @override
  Future<ConsentRecord?> latest(String uid, ConsentType type) async {
    final ofType = (await all(uid)).where((r) => r.type == type);
    return ofType.isEmpty ? null : ofType.last;
  }

  @override
  Future<bool> takeDataReset(String uid) async {
    final h = await _dbs.open(uid);
    final reset = h.wasReset;
    h.wasReset = false;
    return reset;
  }

  @override
  Future<void> closeAll() => _dbs.closeAll();

  static ConsentRecord? _fromRow(QueryRow row) {
    final type = ConsentType.fromWire(row.read<String>('type'));
    // Unknown future type: ignored by this app version.
    if (type == null) return null;
    final received = row.readNullable<int>('received_at');
    return ConsentRecord(
      id: row.read<String>('id'),
      type: type,
      granted: row.read<int>('granted') == 1,
      policyVersion: row.read<String>('policy_version'),
      lang: row.read<String>('lang'),
      clientAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('client_at'),
        isUtc: true,
      ),
      receivedAt: received == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(received, isUtc: true),
      synced: row.read<int>('synced') == 1,
    );
  }
}
