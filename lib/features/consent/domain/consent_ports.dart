import '../../../core/errors/app_failure.dart';
import 'consent_record.dart';

/// `recordConsent` callable (posrednik-api.md pkt 3). Idempotent by `consentId`, so
/// retries are safe. Throws `AppFailure`. Returns the server `receivedAt`.
abstract interface class ConsentApi {
  Future<DateTime> recordConsent(ConsentRecord record);
}

/// Local consent records per account (`consents_local`, ADR-0005 pkt 3), stored in the
/// encrypted account database (`SqliteConsentLocalStore`).
abstract interface class ConsentLocalStore {
  /// True once after the account database was unreadable and recreated empty
  /// (ADR-0005 Aneks A pkt 2, ADR-0011 pkt 9): EK-03 "data reset" variant.
  Future<bool> takeDataReset(String uid);

  /// Closes open account databases (sign-out). Data stays on the device (N3).
  Future<void> closeAll();

  /// Insert or replace by [ConsentRecord.id].
  Future<void> upsert(String uid, ConsentRecord record);

  /// All records of the account, oldest first (by `clientAt`).
  Future<List<ConsentRecord>> all(String uid);

  /// Latest record of [type] (by `clientAt`), or null.
  Future<ConsentRecord?> latest(String uid, ConsentType type);
}

/// Temporary pre-login policy acceptance in `shared_preferences` (no UID).
abstract interface class PendingPolicyStore {
  Future<PendingPolicyAcceptance?> read();
  Future<void> write(PendingPolicyAcceptance value);
  Future<void> clear();
}
