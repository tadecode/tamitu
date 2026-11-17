import '../../../core/errors/app_failure.dart';
import 'consent_record.dart';

/// `recordConsent` callable (posrednik-api.md pkt 3). Idempotent by `consentId`, so
/// retries are safe. Throws `AppFailure`. Returns the server `receivedAt`.
abstract interface class ConsentApi {
  Future<DateTime> recordConsent(ConsentRecord record);
}

/// Local consent records of ONE account (`consents_local`, ADR-0005 pkt 3).
///
/// The target implementation lives in the encrypted per-account database (Drift +
/// SQLCipher) delivered with P3-06; until then [InMemoryConsentLocalStore] is used.
abstract interface class ConsentLocalStore {
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
