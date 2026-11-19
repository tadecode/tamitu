import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/data/firebase_auth_gateway.dart';
import 'package:tamitu/features/auth/data/network_reachability.dart';

/// Gateway path: plugin exception -> classification -> BUG-DEV-2 re-check.
Future<FailureKind> _signInFailure(
  GoogleSignInExceptionCode code,
  String? description, {
  required bool offline,
}) async {
  var probes = 0;
  final failure = await refineCancellation(
    classifyGoogleSignInError(code, description),
    () async {
      probes++;
      return offline;
    },
  );
  if (failure.kind != FailureKind.cancelled &&
      failure.kind != FailureKind.offline) {
    expect(probes, 0, reason: 'only a cancellation is re-checked');
  }
  return failure.kind;
}

void main() {
  group('BUG-DEV-2: "canceled" with no network is offline', () {
    test(
      'canceled after the account pick while offline -> offline (SIGN-13)',
      () async {
        for (final d in [null, 'activity is cancelled by the user.']) {
          expect(
            await _signInFailure(
              GoogleSignInExceptionCode.canceled,
              d,
              offline: true,
            ),
            FailureKind.offline,
            reason: '$d',
          );
        }
      },
    );

    test(
      'unknownError cancellation (status 16) while offline -> offline',
      () async {
        expect(
          await _signInFailure(
            GoogleSignInExceptionCode.unknownError,
            '[16] Account reauth failed.',
            offline: true,
          ),
          FailureKind.offline,
        );
      },
    );

    test(
      'BUG-DEV-1 kept: cancel with network -> cancelled (SIGN-12)',
      () async {
        for (final (code, d) in [
          (GoogleSignInExceptionCode.canceled, null),
          (
            GoogleSignInExceptionCode.canceled,
            'activity is cancelled by the user.',
          ),
          (GoogleSignInExceptionCode.unknownError, '[16] Cancelled by user.'),
          (
            GoogleSignInExceptionCode.unknownError,
            'No credential available: 16: Cancelled by user.',
          ),
        ]) {
          expect(
            await _signInFailure(code, d, offline: false),
            FailureKind.cancelled,
            reason: '${code.name} / $d',
          );
        }
      },
    );

    test(
      'other failures are not probed and keep their kind (SIGN-14)',
      () async {
        for (final offline in [true, false]) {
          expect(
            await _signInFailure(
              GoogleSignInExceptionCode.clientConfigurationError,
              null,
              offline: offline,
            ),
            FailureKind.generic,
          );
          expect(
            await _signInFailure(
              GoogleSignInExceptionCode.unknownError,
              '[10] Developer console is not set up correctly.',
              offline: offline,
            ),
            FailureKind.generic,
          );
          expect(
            await _signInFailure(
              GoogleSignInExceptionCode.interrupted,
              null,
              offline: offline,
            ),
            FailureKind.offline,
          );
        }
      },
    );

    test('refineCancellation does not probe non-cancellations', () async {
      var probes = 0;
      Future<bool> probe() async {
        probes++;
        return true;
      }

      for (final kind in FailureKind.values) {
        if (kind == FailureKind.cancelled) continue;
        final f = await refineCancellation(AppFailure(kind), probe);
        expect(f.kind, kind);
      }
      expect(probes, 0);
    });
  });

  group('NetworkReachability.isOffline', () {
    test('lookup fails with SocketException -> offline', () async {
      final r = NetworkReachability(
        lookup: (_) async => throw const SocketException('Failed host lookup'),
      );
      expect(await r.isOffline(), isTrue);
    });

    test('empty result -> offline', () async {
      final r = NetworkReachability(lookup: (_) async => <InternetAddress>[]);
      expect(await r.isOffline(), isTrue);
    });

    test('resolved address -> online; looks up the configured host', () async {
      String? asked;
      final r = NetworkReachability(
        lookup: (host) async {
          asked = host;
          return [InternetAddress.loopbackIPv4];
        },
      );
      expect(await r.isOffline(), isFalse);
      expect(asked, 'www.googleapis.com');
    });

    test(
      'timeout is "unknown" -> not offline (cancel stays cancelled)',
      () async {
        final never = Completer<List<InternetAddress>>();
        final r = NetworkReachability(
          lookup: (_) => never.future,
          timeout: const Duration(milliseconds: 10),
        );
        expect(await r.isOffline(), isFalse);
      },
    );

    test('unexpected error -> not offline', () async {
      final r = NetworkReachability(
        lookup: (_) async => throw StateError('boom'),
      );
      expect(await r.isOffline(), isFalse);
    });
  });
}
