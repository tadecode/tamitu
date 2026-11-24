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

/// Local Firebase emulators (`TAMITU_USE_FIREBASE_EMULATORS=true`, QA13) are allowed only
/// in a `dev` **debug** build: never in `prod`, never in release or profile (a profile
/// build is close to release and must talk to the real backend).
bool firebaseEmulatorsAllowed({
  required String? flavor,
  required bool debugMode,
}) => flavor == 'dev' && debugMode;

/// Throws when the emulators were requested where they are not allowed, or together
/// with the fake backend (two different test backends at once is a mistake).
void assertFirebaseEmulatorsAllowed({
  required bool requested,
  required bool fakeBackendRequested,
  required String? flavor,
  required bool debugMode,
}) {
  if (!requested) return;
  if (!firebaseEmulatorsAllowed(flavor: flavor, debugMode: debugMode)) {
    throw StateError(
      'TAMITU_USE_FIREBASE_EMULATORS is allowed only in debug dev builds',
    );
  }
  if (fakeBackendRequested) {
    throw StateError(
      'TAMITU_USE_FIREBASE_EMULATORS and TAMITU_FAKE_BACKEND are exclusive',
    );
  }
}

/// `testData` of `generatePlan` (posrednik-api.md pkt 2, ADR-0011 pkt 6): always true in
/// `dev`; in `prod` only for internal builds with `--dart-define=TAMITU_TEST_DATA=true`
/// (until SEC-15 is closed).
bool testDataFor({required String? flavor, required bool requested}) =>
    flavor == 'dev' || requested;
