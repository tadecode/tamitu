import '../../../core/errors/app_failure.dart';
import '../domain/consent_ports.dart';
import '../domain/consent_record.dart';

/// Process-lifetime store, partitioned by UID (account isolation, N3).
///
/// Interim implementation until the encrypted account database (P3-06): records do
/// not survive a restart, so after a restart EK-01 asks for the policy again (EK-03)
/// - a safe default (never lets a user through without a known acceptance).
class InMemoryConsentLocalStore implements ConsentLocalStore {
  final _byUid = <String, Map<String, ConsentRecord>>{};

  @override
  Future<void> upsert(String uid, ConsentRecord record) async {
    (_byUid[uid] ??= {})[record.id] = record;
  }

  @override
  Future<List<ConsentRecord>> all(String uid) async {
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
