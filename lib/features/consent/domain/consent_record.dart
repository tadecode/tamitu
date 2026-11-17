import '../../../core/errors/app_failure.dart';

/// A consent decision (D3), mirrors `consents_local` (docs/data/model-danych.md pkt 2.2)
/// and the `recordConsent` request. [id] is the `consentId` shared with the server.
class ConsentRecord {
  const ConsentRecord({
    required this.id,
    required this.type,
    required this.granted,
    required this.policyVersion,
    required this.lang,
    required this.clientAt,
    this.receivedAt,
    this.synced = false,
  });

  final String id;
  final ConsentType type;
  final bool granted;
  final String policyVersion;

  /// Language the text was shown in (`pl` / `en`).
  final String lang;
  final DateTime clientAt;

  /// Server time from the `recordConsent` response; null until synced (UX17).
  final DateTime? receivedAt;
  final bool synced;

  ConsentRecord markSynced(DateTime receivedAt) => ConsentRecord(
    id: id,
    type: type,
    granted: granted,
    policyVersion: policyVersion,
    lang: lang,
    clientAt: clientAt,
    receivedAt: receivedAt,
    synced: true,
  );

  @override
  String toString() => 'ConsentRecord(${type.wire}, synced: $synced)';
}

/// The policy acceptance kept in `shared_preferences` between the "Sign in" tap and a
/// successful `recordConsent` (ADR-0005 pkt 1, ADR-0011 pkt 10). Contains no UID.
class PendingPolicyAcceptance {
  const PendingPolicyAcceptance({
    required this.consentId,
    required this.version,
    required this.lang,
    required this.acceptedAt,
  });

  final String consentId;
  final String version;
  final String lang;
  final DateTime acceptedAt;

  ConsentRecord toRecord() => ConsentRecord(
    id: consentId,
    type: ConsentType.privacyPolicy,
    granted: true,
    policyVersion: version,
    lang: lang,
    clientAt: acceptedAt,
  );
}
