import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/app.dart';
import 'package:tamitu/app/providers.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/core/ui/app_theme.dart';
import 'package:tamitu/features/auth/data/fake_auth_gateway.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/consent/application/consent_service.dart';
import 'package:tamitu/features/consent/data/fake_consent_api.dart';
import 'package:tamitu/features/consent/data/prefs_pending_policy_store.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';
import 'package:tamitu/features/plan_generation/data/fake_plan_api.dart';
import 'package:tamitu/l10n/app_localizations.dart';

import 'fakes/in_memory_consent_local_store.dart';

/// Deterministic UUID v4-shaped ids.
String Function() idSequence() {
  var n = 0;
  return () {
    n++;
    return '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
  };
}

/// Fakes behind every port, shared by unit and widget tests.
class TestEnv {
  TestEnv({AuthUser? user, DateTime? now})
    : auth = FakeAuthGateway(initialUser: user, nextUser: const AuthUser('u1')),
      api = FakeConsentApi(now: () => now ?? DateTime.utc(2026, 11, 17, 10)),
      local = InMemoryConsentLocalStore(),
      pending = MemoryPendingPolicyStore() {
    consents = ConsentService(
      local: local,
      pending: pending,
      api: api,
      newId: idSequence(),
      now: () => now ?? DateTime.utc(2026, 11, 17, 10),
    );
  }

  final FakeAuthGateway auth;
  final FakeConsentApi api;
  final InMemoryConsentLocalStore local;
  final MemoryPendingPolicyStore pending;
  final plans = FakePlanApi();
  final requestIds = idSequence();

  /// Fake monotonic clock of the EK-07 "AI busy" countdown (advance with the timers).
  Duration mono = Duration.zero;
  late final ConsentService consents;
  final opened = <Uri>[];
  final savedLanguages = <String?>[];

  /// Local, synced acceptance of the policy built into the app.
  Future<void> acceptCurrentPolicy(String uid) => local.upsert(
    uid,
    ConsentRecord(
      id: 'p-$uid',
      type: ConsentType.privacyPolicy,
      granted: true,
      policyVersion: AppConstants.privacyPolicyVersion,
      lang: 'pl',
      clientAt: DateTime.utc(2026, 11, 16),
      receivedAt: DateTime.utc(2026, 11, 16),
      synced: true,
    ),
  );

  List<Override> overrides({String? language}) => [
    authGatewayProvider.overrideWithValue(auth),
    consentServiceProvider.overrideWithValue(consents),
    planApiProvider.overrideWithValue(plans),
    requestIdProvider.overrideWithValue(requestIds),
    aiBusyClockProvider.overrideWithValue(() => mono),
    urlOpenerProvider.overrideWithValue((uri) async {
      opened.add(uri);
      return true;
    }),
    uiLanguageStoreProvider.overrideWithValue(
      _RecordingLanguageStore(savedLanguages),
    ),
    initialUiLanguageProvider.overrideWithValue(language),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides());
    addTearDown(c.dispose);
    return c;
  }
}

class _RecordingLanguageStore implements UiLanguageStore {
  _RecordingLanguageStore(this.saved);

  final List<String?> saved;

  @override
  Future<void> write(String? languageCode) async => saved.add(languageCode);
}

/// Pumps the whole app (router + gate) with the device [locale] and [brightness].
Future<void> pumpApp(
  WidgetTester tester,
  TestEnv env, {
  String locale = 'pl',
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.platformDispatcher.localesTestValue = [Locale(locale)];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(overrides: env.overrides(), child: const TamituApp()),
  );
  await tester.pumpAndSettle();
}

/// Both languages × both themes, as required for screen tests.
const languages = ['pl', 'en'];
const brightnesses = [Brightness.light, Brightness.dark];

/// A single screen outside the router (for variants the gate does not produce yet).
Widget hostScreen(
  TestEnv env,
  Widget screen, {
  String locale = 'pl',
  Brightness brightness = Brightness.light,
}) => ProviderScope(
  overrides: env.overrides(),
  child: MaterialApp(
    locale: Locale(locale),
    theme: brightness == Brightness.light
        ? AppTheme.lightTheme()
        : AppTheme.darkTheme(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: screen,
  ),
);
