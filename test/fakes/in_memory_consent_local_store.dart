import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/domain/consent_ports.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';

/// Process-lifetime store, partitioned by UID (account isolation, N3). Test double only;
/// the app uses `SqliteConsentLocalStore`.
class InMemoryConsentLocalStore implements ConsentLocalStore {
  final _byUid = <String, Map<String, ConsentRecord>>{};

  /// UIDs whose next [takeDataReset] returns true (simulates a lost database key).
  final resetFor = <String>{};
  int closeAllCalls = 0;

  /// Number of next [all] calls that fail (simulates a database open error).
  int failNextReads = 0;

  @override
  Future<bool> takeDataReset(String uid) async => resetFor.remove(uid);

  @override
  Future<void> closeAll() async => closeAllCalls++;

  @override
  Future<void> upsert(String uid, ConsentRecord record) async {
    (_byUid[uid] ??= {})[record.id] = record;
  }

  @override
  Future<List<ConsentRecord>> all(String uid) async {
    if (failNextReads > 0) {
      failNextReads--;
      throw StateError('disk full');
    }
    // Stable: equal clientAt keeps insertion order (later write = later record).
    final list = [...?_byUid[uid]?.values];
    final order = {for (final (i, r) in list.indexed) r.id: i};
    list.sort((a, b) {
      final c = a.clientAt.compareTo(b.clientAt);
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
    return list;
  }

  @override
  Future<ConsentRecord?> latest(String uid, ConsentType type) async {
    final ofType = (await all(uid)).where((r) => r.type == type);
    return ofType.isEmpty ? null : ofType.last;
  }
}
