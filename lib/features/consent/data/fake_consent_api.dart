import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../domain/consent_ports.dart';
import '../domain/consent_record.dart';

/// Server double with the same idempotency as `recordConsent` (first write wins).
/// Used by tests and the demo build until the Firebase projects exist (P3-03).
class FakeConsentApi implements ConsentApi {
  FakeConsentApi({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Stored records by consentId.
  final stored = <String, ({ConsentRecord record, DateTime receivedAt})>{};

  /// Number of calls (including failed ones).
  int calls = 0;

  /// Failures to throw on the next calls, in order.
  final failures = <AppFailure>[];

  /// When set, calls wait for it (to test loading states).
  Completer<void>? gate;

  @override
  Future<DateTime> recordConsent(ConsentRecord record) async {
    calls++;
    final g = gate;
    if (g != null) await g.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    final prev = stored[record.id];
    if (prev != null) return prev.receivedAt;
    final at = _now().toUtc();
    stored[record.id] = (record: record, receivedAt: at);
    return at;
  }
}
