import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_gateway.dart';

/// Sign-in adapter for the Firebase Auth **emulator** (QA13; debug `dev` builds only,
/// see `lib/app/firebase_emulators.dart`).
///
/// Instead of the Google account picker it signs in with a fake Google credential that
/// only the Auth emulator accepts (an unsigned JSON "ID token"). The resulting user has
/// the `google.com` provider, like a real one, so the backend checks
/// (`requireGoogleProvider`) behave as in the cloud. No real account is involved.
class EmulatorAuthGateway implements AuthGateway {
  EmulatorAuthGateway(this._auth, {required this.testSub});

  final FirebaseAuth _auth;

  /// Subject of the fake token (`TAMITU_EMULATOR_TEST_SUB`). It selects the emulator's
  /// Google account (`providerUserInfo.rawId`); the Firebase UID (`user.uid`) is a random
  /// `localId` assigned by the emulator, reused for the same `sub` within one emulator
  /// session (BUG-QA13-UID).
  final String testSub;

  @override
  Stream<AuthUser?> sessionChanges() => _auth
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
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: emulatorGoogleIdToken(testSub)),
      );
      final user = result.user;
      if (user == null) throw const AppFailure(FailureKind.generic);
      return AuthUser(user.uid);
    } on FirebaseAuthException catch (e) {
      throw classifyAuthError(e.code);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(FailureKind.generic);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Fake Google ID token accepted by the Auth emulator (Firebase docs, "Connect your app
/// to the Authentication Emulator"). The e-mail is a reserved `example.com` address,
/// never a real one.
String emulatorGoogleIdToken(String sub) => jsonEncode({
  'sub': sub,
  'email': '$sub@example.com',
  'email_verified': true,
});
