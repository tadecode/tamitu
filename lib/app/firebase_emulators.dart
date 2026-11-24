import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../features/auth/data/emulator_auth_gateway.dart';
import '../features/auth/domain/auth_gateway.dart';
import '../features/consent/data/callable_consent_api.dart';
import '../features/consent/domain/consent_ports.dart';
import '../features/plan_generation/data/callable_plan_api.dart';
import '../features/plan_generation/domain/plan_api.dart';

/// Local Firebase emulators instead of the cloud (QA13): `--dart-define=
/// TAMITU_USE_FIREBASE_EMULATORS=true`, only in a debug `dev` build (environment.dart).
const useFirebaseEmulators = bool.fromEnvironment(
  'TAMITU_USE_FIREBASE_EMULATORS',
);

/// Emulator connection settings, all from `--dart-define` with safe defaults.
///
/// The app connects to Auth and Functions. Firestore is not a client dependency (the app
/// never reads Firestore directly); the Functions emulator uses the Firestore emulator.
class FirebaseEmulatorConfig {
  const FirebaseEmulatorConfig({
    this.host = '10.0.2.2',
    this.authPort = 9099,
    this.functionsPort = 5001,
    this.projectId = 'demo-tamitu',
    this.testSub = 'qa-emulator-user',
  });

  /// From `--dart-define`; ports match `backend/firebase.json`.
  factory FirebaseEmulatorConfig.fromEnvironment() =>
      const FirebaseEmulatorConfig(
        host: String.fromEnvironment(
          'TAMITU_FIREBASE_EMULATOR_HOST',
          defaultValue: '10.0.2.2',
        ),
        projectId: String.fromEnvironment(
          'TAMITU_EMULATOR_PROJECT_ID',
          defaultValue: 'demo-tamitu',
        ),
        testSub: String.fromEnvironment(
          'TAMITU_EMULATOR_TEST_SUB',
          defaultValue: 'qa-emulator-user',
        ),
      );

  /// `10.0.2.2` = the host machine seen from the Android emulator; `127.0.0.1` with
  /// `adb reverse` for a USB phone. Only these are allowed (and only these are let
  /// through as cleartext by `android/app/src/devDebug`).
  final String host;
  final int authPort;
  final int functionsPort;

  /// Must be a `demo-*` project: the emulators then never reach a real Google project.
  final String projectId;

  /// Subject of the fake Google ID token. It identifies the Google account in the Auth
  /// emulator (`providerUserInfo.rawId`), **not** the Firebase UID: the emulator assigns
  /// its own random `localId` (28 chars), stable only while the emulator's data lives
  /// (one session unless `--import`/`--export-on-exit` is used). BUG-QA13-UID.
  final String testSub;

  static const allowedHosts = {'10.0.2.2', '127.0.0.1', 'localhost'};

  /// Throws on a host or project id that could point at something real.
  void validate() {
    if (!allowedHosts.contains(host)) {
      throw StateError('Firebase emulator host must be one of $allowedHosts');
    }
    if (!RegExp(r'^demo-[a-z0-9-]{1,24}$').hasMatch(projectId)) {
      throw StateError('Firebase emulator project id must start with demo-');
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(testSub)) {
      throw StateError('Invalid TAMITU_EMULATOR_TEST_SUB');
    }
  }

  /// Placeholder options for a `demo-*` project (not keys: the emulators accept any
  /// value). Used instead of google-services.json, so an emulator build never talks to
  /// `tamitu-dev-tadecode`.
  FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
  );
}

/// Name of the separate Firebase app used for the emulators. A named app never clashes
/// with the default app that Android may auto-initialise from google-services.json.
const emulatorAppName = 'tamitu-emulators';

/// Connects Auth and Functions of a dedicated Firebase app to the local emulators.
/// App Check is deliberately not activated (the Functions emulator runs with
/// `ENFORCE_APP_CHECK=false`; activating it would call the real App Check service).
Future<(AuthGateway, ConsentApi, PlanApi)> connectFirebaseEmulators(
  FirebaseEmulatorConfig config,
) async {
  config.validate();
  final app = await Firebase.initializeApp(
    name: emulatorAppName,
    options: config.firebaseOptions,
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator(config.host, config.authPort);
  final functions = FirebaseFunctions.instanceFor(
    app: app,
    region: CallableConsentApi.region,
  );
  functions.useFunctionsEmulator(config.host, config.functionsPort);
  return (
    EmulatorAuthGateway(auth, testSub: config.testSub),
    CallableConsentApi(functions),
    // Emulator builds are debug `dev` only: always test data.
    CallablePlanApi(functions, testData: true),
  );
}
