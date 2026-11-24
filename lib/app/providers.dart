import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/auth/domain/auth_gateway.dart';
import '../features/consent/application/consent_service.dart';
import '../features/generation/application/ai_busy_controller.dart'
    show MonotonicClock;
import '../features/plan_generation/domain/plan_api.dart';

/// Ports wired in `bootstrap.dart` (Firebase or fakes) and overridden in tests.
final authGatewayProvider = Provider<AuthGateway>(
  (ref) => throw UnimplementedError('authGatewayProvider must be overridden'),
);

final consentServiceProvider = Provider<ConsentService>(
  (ref) =>
      throw UnimplementedError('consentServiceProvider must be overridden'),
);

/// `generatePlan` port (P3-05, TAM-101).
final planApiProvider = Provider<PlanApi>(
  (ref) => throw UnimplementedError('planApiProvider must be overridden'),
);

/// New `requestId` (UUID v4) for every `generatePlan` attempt.
final requestIdProvider = Provider<String Function()>(
  (ref) => throw UnimplementedError('requestIdProvider must be overridden'),
);

/// Monotonic clock of the EK-07 "AI busy" countdown; null = the real one (tests inject
/// a fake one next to the fake async timers).
final aiBusyClockProvider = Provider<MonotonicClock?>((ref) => null);

/// Stores the UI language chosen in the app (`shared_preferences.uiLanguage`).
abstract interface class UiLanguageStore {
  Future<void> write(String? languageCode);
}

class NoopUiLanguageStore implements UiLanguageStore {
  @override
  Future<void> write(String? languageCode) async {}
}

final uiLanguageStoreProvider = Provider<UiLanguageStore>(
  (ref) => NoopUiLanguageStore(),
);

/// Language saved at the previous run (read in bootstrap, before the first frame).
final initialUiLanguageProvider = Provider<String?>((ref) => null);

/// Explicit UI language (`pl`/`en`) or null = follow the device (ADR-0006).
class UiLanguageController extends Notifier<String?> {
  @override
  String? build() => ref.read(initialUiLanguageProvider);

  void set(String languageCode) {
    state = languageCode;
    ref.read(uiLanguageStoreProvider).write(languageCode).ignore();
  }
}

final uiLanguageProvider = NotifierProvider<UiLanguageController, String?>(
  UiLanguageController.new,
);

/// Opens a URL outside the app (policy, Google Play). Returns false on failure.
typedef UrlOpener = Future<bool> Function(Uri uri);

final urlOpenerProvider = Provider<UrlOpener>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);

/// One-shot messages for EK-02 (snackbar after expiry or account deletion).
enum WelcomeFlash { sessionExpired, accountDeleted }

class WelcomeFlashController extends Notifier<WelcomeFlash?> {
  @override
  WelcomeFlash? build() => null;

  void show(WelcomeFlash flash) => state = flash;

  WelcomeFlash? take() {
    final f = state;
    state = null;
    return f;
  }
}

final welcomeFlashProvider =
    NotifierProvider<WelcomeFlashController, WelcomeFlash?>(
      WelcomeFlashController.new,
    );

/// Language code used for consent records and links: the resolved UI locale.
String languageOf(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'pl';
