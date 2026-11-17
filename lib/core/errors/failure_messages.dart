import '../../l10n/app_localizations.dart';
import 'app_failure.dart';

/// EK-16 message: optional title + body; never contains codes or server details.
class FailureMessage {
  const FailureMessage({this.title, required this.body});

  final String? title;
  final String body;
}

/// EK-16 catalogue for generic surfaces (CMP-13 / CMP-18). Screens with their own
/// texts (EK-02, EK-03, EK-06) map offline/generic themselves.
///
/// `consentRequired` is not a message: callers route to EK-03 / EK-06 or "Update the
/// app" via `ConsentService.resolveConsentRequired`; here it falls back to "update".
FailureMessage failureMessage(
  AppLocalizations l10n,
  AppFailure f, {
  required String Function(DateTime local) formatTime,
}) {
  switch (f.kind) {
    case FailureKind.offline:
      return FailureMessage(
        title: l10n.errorOfflineTitle,
        body: l10n.errorOfflineBody,
      );
    case FailureKind.timeout:
      return FailureMessage(
        title: l10n.errorGenerateTitle,
        body: l10n.errorTimeoutBody,
      );
    case FailureKind.limitExceeded:
      final resetAt = f.resetAt;
      final limit = f.limit;
      if (resetAt == null || limit == null) {
        return FailureMessage(
          title: l10n.errorGenericTitle,
          body: l10n.errorGenericBody,
        );
      }
      return FailureMessage(
        title: l10n.errorLimitTitle,
        body: l10n.errorLimitBody(limit, formatTime(resetAt.toLocal())),
      );
    case FailureKind.aiUnavailable:
      return FailureMessage(
        title: l10n.errorGenerateTitle,
        body: l10n.errorAiUnavailableBody,
      );
    case FailureKind.aiInvalidResponse:
      return FailureMessage(
        title: l10n.errorGenerateTitle,
        body: l10n.errorAiInvalidBody,
      );
    case FailureKind.testDataOnly:
      return FailureMessage(
        title: l10n.errorGenerateTitle,
        body: l10n.errorUnavailableForAccountBody,
      );
    case FailureKind.unsupportedVersion:
    case FailureKind.consentRequired:
      return FailureMessage(
        title: l10n.errorUpdateTitle,
        body: l10n.errorUpdateBody,
      );
    case FailureKind.unauthenticated:
      return FailureMessage(body: l10n.errorSessionExpired);
    case FailureKind.invalidArgument:
      return FailureMessage(body: l10n.errorInvalidFormBody);
    case FailureKind.cancelled:
    case FailureKind.reauthRequired:
    case FailureKind.generic:
      return FailureMessage(
        title: l10n.errorGenericTitle,
        body: l10n.errorGenericBody,
      );
  }
}
