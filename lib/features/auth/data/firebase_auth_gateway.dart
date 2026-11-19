import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_gateway.dart';

/// Firebase Auth + Google Sign-In (Credential Manager) adapter (ADR-0004, option 1).
///
/// Not exercised by unit tests (needs a Firebase project, P3-03/Q10); the error
/// classification it relies on is tested in `app_failure_test.dart` and
/// `google_sign_in_errors_test.dart`.
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway({
    FirebaseAuth? auth,
    GoogleSignIn? google,
    this.serverClientId,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// Web client ID of the Firebase project (per flavor, via `--dart-define`); when null
  /// the plugin reads `default_web_client_id` from the Android resources.
  final String? serverClientId;

  Future<void>? _initialized;

  Future<void> _ensureInitialized() =>
      _initialized ??= _google.initialize(serverClientId: serverClientId);

  @override
  Stream<AuthUser?> sessionChanges() =>
      // ADR-0004: idTokenChanges; distinct() drops the hourly token refreshes (same UID),
      // so the gate and the consent sync do not re-run every hour (review PR #57 #5).
      _auth
          .idTokenChanges()
          .map((u) => u == null ? null : AuthUser(u.uid))
          .distinct();

  @override
  AuthUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AuthUser(u.uid);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AppFailure(FailureKind.generic);
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = result.user;
      if (user == null) throw const AppFailure(FailureKind.generic);
      return AuthUser(user.uid);
    } on GoogleSignInException catch (e) {
      throw classifyGoogleSignInError(e.code, e.description);
    } on FirebaseAuthException catch (e) {
      throw classifyAuthError(e.code);
    } on AppFailure {
      rethrow;
    } catch (_) {
      // Never surface or log provider messages (SEC-29).
      throw const AppFailure(FailureKind.generic);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _google.signOut();
    } catch (_) {
      // Google sign-out failure must not keep the Firebase session alive.
    }
    await _auth.signOut();
  }
}

/// `google_sign_in` (Credential Manager) has no dedicated network code (BUG-3, ADR-0011
/// pkt 2). `interrupted` and failures whose description mentions the network are shown
/// as "offline" (retry); cancel -> cancelled; everything else -> generic. The
/// description is only inspected here, never shown or logged (SEC-29).
/// Network classification confirmed on a device (QA SIGN-13).
///
/// Cancellation (BUG-DEV-1, US-001 AC2): `google_sign_in_android` 7.2 reports
/// `canceled` only for `GetCredentialCancellationException`. A user cancel can also
/// arrive as `unknownError` – androidx `credentials-play-services-auth` 1.6 turns an
/// `ApiException` with status 16 (`CommonStatusCodes.CANCELED`, e.g. "[16] Cancelled
/// by user" / "16: Cancelled by user" after repeated cancels) or an unexpected
/// activity result into `GetCredentialUnknownException` / `NoCredentialException`
/// ("No credential available: …"). Those are classified as cancelled too, so backing
/// out of the account chooser never shows the error message.
AppFailure classifyGoogleSignInError(
  GoogleSignInExceptionCode code,
  String? description,
) {
  switch (code) {
    case GoogleSignInExceptionCode.canceled:
      return const AppFailure(FailureKind.cancelled);
    case GoogleSignInExceptionCode.interrupted:
      return const AppFailure(FailureKind.offline);
    case GoogleSignInExceptionCode.unknownError:
      final d = description?.toLowerCase() ?? '';
      if (_isUserCancellation(d)) {
        return const AppFailure(FailureKind.cancelled);
      }
      return d.contains('network') ||
              d.contains('offline') ||
              d.contains('internet')
          ? const AppFailure(FailureKind.offline)
          : const AppFailure(FailureKind.generic);
    default:
      return const AppFailure(FailureKind.generic);
  }
}

/// Status 16 = `CommonStatusCodes.CANCELED` ("[16] …" from `ApiException.getMessage`,
/// "16: …" from the one-tap wrappers).
final _canceledStatus = RegExp(r'\[16\]|(^|: )16: ');

bool _isUserCancellation(String lowerDescription) =>
    lowerDescription.contains('cancel') ||
    _canceledStatus.hasMatch(lowerDescription);
