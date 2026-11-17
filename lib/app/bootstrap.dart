import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/db/account_databases.dart';
import '../features/auth/data/fake_auth_gateway.dart';
import '../features/auth/data/firebase_auth_gateway.dart';
import '../features/auth/domain/auth_gateway.dart';
import '../features/consent/application/consent_service.dart';
import '../features/consent/data/callable_consent_api.dart';
import '../features/consent/data/fake_consent_api.dart';
import '../features/consent/data/prefs_pending_policy_store.dart';
import '../features/consent/data/sqlite_consent_local_store.dart';
import '../features/consent/domain/consent_ports.dart';
import 'environment.dart';
import 'providers.dart';

/// Demo build without Firebase: `--dart-define=TAMITU_FAKE_BACKEND=true`, allowed only
/// in a debug/profile `dev` build (environment.dart). Until the Firebase projects exist
/// (P3-03, Q10) this is the only way to click through EK-01/02/03/06 on a device.
const fakeBackend = bool.fromEnvironment('TAMITU_FAKE_BACKEND');

/// Web client ID per flavor (P3-03); optional - the plugin can read it from resources.
const _serverClientId = String.fromEnvironment(
  'TAMITU_GOOGLE_SERVER_CLIENT_ID',
);

/// App Check debug token for `dev` (registered in the Firebase console; passed at build
/// time from a local/CI secret, never committed – SEC-16).
const _appCheckDebugToken = String.fromEnvironment(
  'TAMITU_APP_CHECK_DEBUG_TOKEN',
);

/// Builds provider overrides for the real app.
Future<List<Override>> bootstrapOverrides() async {
  assertFakeBackendAllowed(
    requested: fakeBackend,
    flavor: appFlavor,
    releaseMode: kReleaseMode,
  );
  final prefs = SharedPreferencesAsync();
  final AuthGateway auth;
  final ConsentApi api;
  if (fakeBackend) {
    auth = FakeAuthGateway();
    api = FakeConsentApi();
  } else {
    // Firebase options come from google-services.json per flavor (P3-03); without it
    // initialisation fails and the app cannot sign in (by design: no keys in the repo).
    await Firebase.initializeApp();
    // App Check before the first callable: the SDK attaches tokens only once activated.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: switch (appCheckModeFor(appFlavor)) {
        AppCheckMode.playIntegrity => const AndroidPlayIntegrityProvider(),
        AppCheckMode.debug => AndroidDebugProvider(
          debugToken: _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken,
        ),
      },
    );
    auth = FirebaseAuthGateway(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    api = CallableConsentApi(
      FirebaseFunctions.instanceFor(region: CallableConsentApi.region),
    );
  }
  const uuid = Uuid();
  final consents = ConsentService(
    local: SqliteConsentLocalStore(
      AccountDatabases(
        directory: getApplicationSupportDirectory,
        keys: SecureStorageDbKeyStore(),
      ),
    ),
    pending: PrefsPendingPolicyStore(prefs),
    api: api,
    newId: uuid.v4,
  );
  String? language;
  try {
    final saved = await prefs.getString(_uiLanguageKey);
    language = saved == 'pl' || saved == 'en' ? saved : null;
  } catch (_) {
    language = null;
  }
  return [
    authGatewayProvider.overrideWithValue(auth),
    consentServiceProvider.overrideWithValue(consents),
    uiLanguageStoreProvider.overrideWithValue(_PrefsUiLanguageStore(prefs)),
    initialUiLanguageProvider.overrideWithValue(language),
  ];
}

const _uiLanguageKey = 'uiLanguage';

class _PrefsUiLanguageStore implements UiLanguageStore {
  _PrefsUiLanguageStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<void> write(String? languageCode) => languageCode == null
      ? _prefs.remove(_uiLanguageKey)
      : _prefs.setString(_uiLanguageKey, languageCode);
}
