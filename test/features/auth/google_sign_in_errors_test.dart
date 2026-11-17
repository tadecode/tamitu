import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/data/firebase_auth_gateway.dart';

void main() {
  test('BUG-3: network failures of google_sign_in are shown as offline', () {
    expect(
      classifyGoogleSignInError(
        GoogleSignInExceptionCode.interrupted,
        null,
      ).kind,
      FailureKind.offline,
    );
    expect(
      classifyGoogleSignInError(
        GoogleSignInExceptionCode.unknownError,
        'android.credentials.GetCredentialException: Network error',
      ).kind,
      FailureKind.offline,
    );
  });

  test('cancel -> cancelled; configuration and unknown errors -> generic', () {
    expect(
      classifyGoogleSignInError(GoogleSignInExceptionCode.canceled, null).kind,
      FailureKind.cancelled,
    );
    for (final code in [
      GoogleSignInExceptionCode.clientConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError,
      GoogleSignInExceptionCode.uiUnavailable,
      GoogleSignInExceptionCode.userMismatch,
    ]) {
      expect(
        classifyGoogleSignInError(code, 'network').kind,
        FailureKind.generic,
        reason: code.name,
      );
    }
    expect(
      classifyGoogleSignInError(
        GoogleSignInExceptionCode.unknownError,
        'No credential',
      ).kind,
      FailureKind.generic,
    );
  });
}
