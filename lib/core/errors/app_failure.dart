/// Client-side classification of errors (ADR-0011 pkt 2 and 7, posrednik-api.md pkt 6,
/// EK-16). Only kinds and contract constants are kept: never messages, stack traces or
/// error `details` beyond the documented fields (SEC-29).
library;

/// Kinds of failures the UI can map to a message from the EK-16 catalogue.
enum FailureKind {
  /// Transport error / no network (shown only after a failed attempt).
  offline,

  /// Client timeout (`deadline-exceeded`).
  timeout,

  /// The user cancelled (e.g. Google account picker).
  cancelled,

  /// Session expired or user deleted -> EK-02 with a snackbar.
  unauthenticated,

  /// `consent_required` with [AppFailure.consentType].
  consentRequired,

  /// `unsupported_version` -> "Update the app".
  unsupportedVersion,

  /// `invalid_argument` with optional [AppFailure.field].
  invalidArgument,

  /// `limit_exceeded` with [AppFailure.limit] and [AppFailure.resetAt].
  limitExceeded,
  aiUnavailable,
  aiInvalidResponse,
  testDataOnly,
  reauthRequired,

  /// `internal`, `app_check_failed`, unknown codes and anything unexpected.
  generic,
}

/// Consent types from the contract (`privacy_policy`, `ai_processing`).
enum ConsentType {
  privacyPolicy('privacy_policy'),
  aiProcessing('ai_processing');

  const ConsentType(this.wire);

  /// Value used in the API and in local records.
  final String wire;

  static ConsentType? fromWire(Object? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// A classified failure. [toString] exposes only the kind, so accidental string
/// conversion can never leak user content or server details.
class AppFailure implements Exception {
  const AppFailure(
    this.kind, {
    this.consentType,
    this.field,
    this.limit,
    this.resetAt,
    this.slotReleased,
  });

  final FailureKind kind;
  final ConsentType? consentType;
  final String? field;
  final int? limit;
  final DateTime? resetAt;

  /// `details.slotReleased` of `ai_unavailable` / `ai_invalid_response` (contract v0.5):
  /// true = the attempt did not use the daily limit, false = it counted,
  /// null = unknown (field missing, older server) -> "may have counted".
  final bool? slotReleased;

  @override
  String toString() => 'AppFailure(${kind.name})';
}

/// Maps a callable error (`FirebaseFunctionsException.code` + `details`) to a failure.
///
/// `unavailable` WITHOUT `details.code` is a transport error ("offline"); with an
/// application code the contract table applies; unknown codes -> generic.
AppFailure classifyCallableError({required String code, Object? details}) {
  final map = details is Map ? details : const <Object?, Object?>{};
  final appCode = map['code'];
  if (appCode is String) {
    switch (appCode) {
      case 'consent_required':
        final type = ConsentType.fromWire(map['consentType']);
        // An unknown/missing consentType is treated as the policy (fail-closed like the server).
        return AppFailure(
          FailureKind.consentRequired,
          consentType: type ?? ConsentType.privacyPolicy,
        );
      case 'unsupported_version':
        return const AppFailure(FailureKind.unsupportedVersion);
      case 'unauthenticated':
        return const AppFailure(FailureKind.unauthenticated);
      case 'invalid_argument':
        final field = map['field'];
        return AppFailure(
          FailureKind.invalidArgument,
          field: field is String ? field : null,
        );
      case 'limit_exceeded':
        final limit = map['limit'];
        final resetAt = map['resetAt'];
        return AppFailure(
          FailureKind.limitExceeded,
          limit: limit is int ? limit : null,
          resetAt: resetAt is String
              ? DateTime.tryParse(resetAt)?.toUtc()
              : null,
        );
      case 'ai_unavailable':
        return AppFailure(
          FailureKind.aiUnavailable,
          slotReleased: _slotReleased(map),
        );
      case 'ai_invalid_response':
        return AppFailure(
          FailureKind.aiInvalidResponse,
          slotReleased: _slotReleased(map),
        );
      case 'test_data_only':
        return const AppFailure(FailureKind.testDataOnly);
      case 'reauth_required':
        return const AppFailure(FailureKind.reauthRequired);
      default:
        // internal, app_check_failed (not disclosed), not_implemented, unknown.
        return const AppFailure(FailureKind.generic);
    }
  }
  switch (code) {
    case 'unavailable':
      return const AppFailure(FailureKind.offline);
    case 'deadline-exceeded':
      return const AppFailure(FailureKind.timeout);
    case 'unauthenticated':
      return const AppFailure(FailureKind.unauthenticated);
    default:
      return const AppFailure(FailureKind.generic);
  }
}

/// `details.slotReleased` only when it is a real bool; anything else = unknown (null).
bool? _slotReleased(Map<Object?, Object?> details) {
  final v = details['slotReleased'];
  return v is bool ? v : null;
}

/// Maps a `FirebaseAuthException.code` to a failure (ADR-0011 pkt 2).
AppFailure classifyAuthError(String code) {
  switch (code) {
    case 'network-request-failed':
      return const AppFailure(FailureKind.offline);
    case 'user-not-found':
    case 'user-disabled':
    case 'user-token-expired':
    case 'invalid-user-token':
      return const AppFailure(FailureKind.unauthenticated);
    default:
      return const AppFailure(FailureKind.generic);
  }
}
