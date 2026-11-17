import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_gateway.dart';

/// Firebase Auth + Google Sign-In (Credential Manager) adapter (ADR-0004, option 1).
///
/// Not exercised by unit tests (needs a Firebase project, P3-03/Q10); the error
/// classification it relies on is tested in `app_failure_test.dart`.
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
      _auth.idTokenChanges().map((u) => u == null ? null : AuthUser(u.uid));

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
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled => const AppFailure(
          FailureKind.cancelled,
        ),
        _ => const AppFailure(FailureKind.generic),
      };
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
