/// Build-environment rules for bootstrap, kept pure so they are unit-tested.
library;

/// App Check provider per flavor (ADR-0002, D17; review PR #57 #2).
enum AppCheckMode {
  /// Play Integrity (`prod`, and any unknown flavor – fail-safe).
  playIntegrity,

  /// Debug provider (`dev`); the debug token is registered in the Firebase console
  /// and passed via `--dart-define`, never committed (SEC-16).
  debug,
}

AppCheckMode appCheckModeFor(String? flavor) =>
    flavor == 'dev' ? AppCheckMode.debug : AppCheckMode.playIntegrity;

/// The fake backend (`TAMITU_FAKE_BACKEND=true`) is allowed only in a non-release `dev`
/// build (review PR #57 #3): a release or `prod` build with the flag would "sign in"
/// without Google and never store consent proof.
bool fakeBackendAllowed({required String? flavor, required bool releaseMode}) =>
    flavor == 'dev' && !releaseMode;

/// Throws when the fake backend was requested where it is not allowed.
void assertFakeBackendAllowed({
  required bool requested,
  required String? flavor,
  required bool releaseMode,
}) {
  if (requested &&
      !fakeBackendAllowed(flavor: flavor, releaseMode: releaseMode)) {
    throw StateError(
      'TAMITU_FAKE_BACKEND is allowed only in debug/profile dev builds',
    );
  }
}
