import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/errors/app_failure.dart';

void main() {
  group('classifyCallableError (ADR-0011 pkt 2, posrednik-api.md pkt 6)', () {
    test(
      'unavailable WITHOUT details.code is a transport error -> offline',
      () {
        expect(
          classifyCallableError(code: 'unavailable').kind,
          FailureKind.offline,
        );
        expect(
          classifyCallableError(code: 'unavailable', details: {'x': 1}).kind,
          FailureKind.offline,
        );
      },
    );

    test(
      'unavailable WITH details.code follows the contract (ai_unavailable)',
      () {
        expect(
          classifyCallableError(
            code: 'unavailable',
            details: {'code': 'ai_unavailable'},
          ).kind,
          FailureKind.aiUnavailable,
        );
      },
    );

    test('TAM-94: details.slotReleased is read only as a bool (v0.5)', () {
      bool? slot(String code, Map<String, Object?> extra) =>
          classifyCallableError(
            code: 'internal',
            details: {'code': code, ...extra},
          ).slotReleased;
      for (final code in ['ai_unavailable', 'ai_invalid_response']) {
        expect(slot(code, {'slotReleased': true}), isTrue);
        expect(slot(code, {'slotReleased': false}), isFalse);
        expect(slot(code, {}), isNull);
        expect(slot(code, {'slotReleased': 'true'}), isNull);
        expect(slot(code, {'slotReleased': 1}), isNull);
      }
      expect(slot('internal', {'slotReleased': true}), isNull);
    });

    test(
      'deadline-exceeded -> timeout; unauthenticated -> unauthenticated',
      () {
        expect(
          classifyCallableError(code: 'deadline-exceeded').kind,
          FailureKind.timeout,
        );
        expect(
          classifyCallableError(code: 'unauthenticated').kind,
          FailureKind.unauthenticated,
        );
      },
    );

    test('consent_required carries consentType; unknown type is treated as the policy', () {
      final ai = classifyCallableError(
        code: 'failed-precondition',
        details: {'code': 'consent_required', 'consentType': 'ai_processing'},
      );
      expect(ai.kind, FailureKind.consentRequired);
      expect(ai.consentType, ConsentType.aiProcessing);
      final odd = classifyCallableError(
        code: 'failed-precondition',
        details: {'code': 'consent_required', 'consentType': 'ads'},
      );
      expect(odd.consentType, ConsentType.privacyPolicy);
    });

    test('limit_exceeded parses limit and resetAt (UTC)', () {
      final f = classifyCallableError(
        code: 'resource-exhausted',
        details: {
          'code': 'limit_exceeded',
          'limit': 5,
          'resetAt': '2026-11-17T23:00:00Z',
        },
      );
      expect(f.kind, FailureKind.limitExceeded);
      expect(f.limit, 5);
      expect(f.resetAt, DateTime.utc(2026, 11, 17, 23));
    });

    test('every contract code maps; app_check_failed, internal and unknown are generic', () {
      const expected = {
        'unsupported_version': FailureKind.unsupportedVersion,
        'invalid_argument': FailureKind.invalidArgument,
        'ai_invalid_response': FailureKind.aiInvalidResponse,
        'test_data_only': FailureKind.testDataOnly,
        'reauth_required': FailureKind.reauthRequired,
        'unauthenticated': FailureKind.unauthenticated,
        'app_check_failed': FailureKind.generic,
        'internal': FailureKind.generic,
        'not_implemented': FailureKind.generic,
        'brand_new_code': FailureKind.generic,
      };
      expected.forEach((code, kind) {
        expect(
          classifyCallableError(code: 'internal', details: {'code': code}).kind,
          kind,
          reason: code,
        );
      });
      expect(
        classifyCallableError(code: 'permission-denied').kind,
        FailureKind.generic,
      );
    });

    test('invalid_argument keeps only the field path', () {
      final f = classifyCallableError(
        code: 'invalid-argument',
        details: {'code': 'invalid_argument', 'field': 'policyVersion'},
      );
      expect(f.field, 'policyVersion');
    });
  });

  test('classifyAuthError: network-request-failed -> offline, deleted user -> unauthenticated', () {
    expect(
      classifyAuthError('network-request-failed').kind,
      FailureKind.offline,
    );
    expect(
      classifyAuthError('user-not-found').kind,
      FailureKind.unauthenticated,
    );
    expect(
      classifyAuthError('user-disabled').kind,
      FailureKind.unauthenticated,
    );
    expect(
      classifyAuthError('user-token-expired').kind,
      FailureKind.unauthenticated,
    );
    expect(classifyAuthError('invalid-credential').kind, FailureKind.generic);
  });

  test('toString exposes the kind only (SEC-29: no details in logs)', () {
    const f = AppFailure(FailureKind.invalidArgument, field: 'trip.lodging');
    expect(f.toString(), 'AppFailure(invalidArgument)');
  });
}
