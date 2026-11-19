import 'dart:async';
import 'dart:io';

import '../../../core/errors/app_failure.dart';

/// Resolves a host name; injectable for tests (defaults to [InternetAddress.lookup]).
typedef HostLookup = Future<List<InternetAddress>> Function(String host);

/// Reactive "is the device offline?" check used only after a failed sign-in attempt
/// (BUG-DEV-2, ADR-0011 pkt 2: no connectivity package, no `ACCESS_NETWORK_STATE`).
///
/// A DNS lookup of a Google host needs only the `INTERNET` permission. It sends no
/// user data (SEC-29) and nothing is logged. Only a definite failure (`SocketException`)
/// counts as offline; a timeout or any other error is "unknown" and reported as
/// online, so a real cancellation is never shown as a network problem by mistake.
class NetworkReachability {
  NetworkReachability({
    HostLookup? lookup,
    this.host = 'www.googleapis.com',
    this.timeout = const Duration(seconds: 2),
  }) : _lookup = lookup ?? InternetAddress.lookup;

  final HostLookup _lookup;
  final String host;
  final Duration timeout;

  Future<bool> isOffline() async {
    try {
      final addresses = await _lookup(host).timeout(timeout);
      return addresses.isEmpty;
    } on SocketException {
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// BUG-DEV-2: with no network after the account is picked, Google Play services ends
/// the "AccountReauth" step with `NETWORK_ERROR` but Credential Manager reports
/// `GetCredentialCancellationException` (`canceled`), so the exception alone cannot
/// tell it from a user cancel. A "cancelled" result is therefore re-checked: offline
/// -> [FailureKind.offline] (CMP-13, US-001 AC3); otherwise it stays "cancelled"
/// (US-001 AC2, BUG-DEV-1). Any other failure is returned unchanged without a probe.
Future<AppFailure> refineCancellation(
  AppFailure failure,
  Future<bool> Function() isOffline,
) async {
  if (failure.kind != FailureKind.cancelled) return failure;
  return await isOffline() ? const AppFailure(FailureKind.offline) : failure;
}
