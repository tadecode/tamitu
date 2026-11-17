/// Signed-in user as the app sees it: only the UID (ADR-0004, D1). E-mail and display name
/// from the SDK are never read, stored, logged or shown.
class AuthUser {
  const AuthUser(this.uid);

  final String uid;

  @override
  bool operator ==(Object other) => other is AuthUser && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'AuthUser(<redacted>)';
}

/// Authentication port (ADR-0004). Implementations throw `AppFailure`
/// (cancelled, offline, generic, ...) and never expose provider error messages.
abstract interface class AuthGateway {
  /// Session changes (Firebase `idTokenChanges`, ADR-0004), de-duplicated by UID so a
  /// token refresh is not a new session; emits the current state first.
  Stream<AuthUser?> sessionChanges();

  /// Current session, available offline (restored by the SDK after restart).
  AuthUser? get currentUser;

  /// Google account picker -> Firebase credential. Basic sign-in only, no extra scopes.
  Future<AuthUser> signInWithGoogle();

  /// `GoogleSignIn.signOut()` + `FirebaseAuth.signOut()` (US-002).
  Future<void> signOut();
}
