import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/data/firebase_auth_gateway.dart';

FailureKind _kind(GoogleSignInExceptionCode code, [String? description]) =>
    classifyGoogleSignInError(code, description).kind;

void main() {
  test('BUG-3: network failures of google_sign_in are shown as offline', () {
    expect(_kind(GoogleSignInExceptionCode.interrupted), FailureKind.offline);
    // Retryable ApiException (7 NETWORK_ERROR, 20) -> GetCredentialInterruptedException.
    expect(
      _kind(GoogleSignInExceptionCode.interrupted, '[7] Network error'),
      FailureKind.offline,
    );
    expect(
      _kind(
        GoogleSignInExceptionCode.unknownError,
        'android.credentials.GetCredentialException: Network error',
      ),
      FailureKind.offline,
    );
    expect(
      _kind(GoogleSignInExceptionCode.unknownError, 'Device is offline'),
      FailureKind.offline,
    );
  });

  group('BUG-DEV-1: user cancellation is always "cancelled"', () {
    test('canceled code, with or without a description', () {
      expect(_kind(GoogleSignInExceptionCode.canceled), FailureKind.cancelled);
      for (final d in [
        'activity is cancelled by the user.',
        '[16] Cancelled by user.',
        'android.credentials.GetCredentialException.TYPE_USER_CANCELED',
        '',
      ]) {
        expect(
          _kind(GoogleSignInExceptionCode.canceled, d),
          FailureKind.cancelled,
          reason: d,
        );
      }
    });

    test(
      'unknownError carrying a cancellation (ApiException 16 and similar)',
      () {
        for (final d in [
          // GetCredentialUnknownException(ApiException.message) for status 16
          '[16] Cancelled by user.',
          '[16] Account reauth failed.',
          // one-tap wrapper after repeated cancels (cool-down)
          'During begin sign in, failure response from one tap: 16: Cancelled by user.',
          // NoCredentialException with throwForNoAuth (plugin prefix)
          'No credential available: 16: Cancelled by user.',
          // CredentialProviderController.generateErrorStringCanceled
          'activity is cancelled by the user.',
          'User canceled the selector',
        ]) {
          expect(
            _kind(GoogleSignInExceptionCode.unknownError, d),
            FailureKind.cancelled,
            reason: d,
          );
        }
      },
    );

    test('cancellation wins over a network word in the same description', () {
      expect(
        _kind(
          GoogleSignInExceptionCode.unknownError,
          'Network request cancelled by the user',
        ),
        FailureKind.cancelled,
      );
    });
  });

  group('real failures stay "generic"', () {
    test('configuration and UI codes ignore the description', () {
      for (final code in [
        GoogleSignInExceptionCode.clientConfigurationError,
        GoogleSignInExceptionCode.providerConfigurationError,
        GoogleSignInExceptionCode.uiUnavailable,
        GoogleSignInExceptionCode.userMismatch,
      ]) {
        for (final d in [null, 'network', 'cancelled', '[16] Cancelled']) {
          expect(
            _kind(code, d),
            FailureKind.generic,
            reason: '${code.name} / $d',
          );
        }
      }
    });

    test('unknownError without cancel or network signals', () {
      for (final d in <String?>[
        null,
        '',
        'No credential',
        'No credential available: [28433] Cannot find a matching credential.',
        '[10] Developer console is not set up correctly.',
        '[8] Internal error',
        'activity with result code: 1 indicating not RESULT_OK',
        'Authenticate returned no credential without an error',
        'Error code 116',
        '[160] unexpected',
        'Android 16: unsupported',
      ]) {
        expect(
          _kind(GoogleSignInExceptionCode.unknownError, d),
          FailureKind.generic,
          reason: '$d',
        );
      }
    });
  });

  test('every GoogleSignInExceptionCode has a defined classification', () {
    const expected = {
      GoogleSignInExceptionCode.canceled: FailureKind.cancelled,
      GoogleSignInExceptionCode.interrupted: FailureKind.offline,
      GoogleSignInExceptionCode.unknownError: FailureKind.generic,
      GoogleSignInExceptionCode.clientConfigurationError: FailureKind.generic,
      GoogleSignInExceptionCode.providerConfigurationError: FailureKind.generic,
      GoogleSignInExceptionCode.uiUnavailable: FailureKind.generic,
      GoogleSignInExceptionCode.userMismatch: FailureKind.generic,
    };
    expect(
      expected.keys.toSet(),
      GoogleSignInExceptionCode.values.toSet(),
      reason: 'new plugin code: decide its classification (BUG-DEV-1)',
    );
    for (final e in expected.entries) {
      expect(_kind(e.key), e.value, reason: e.key.name);
    }
  });
}
