import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/ui/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

/// Root widget. UI language: chosen in the app, else the device language if PL/EN,
/// else English (ADR-0006; EK-02 data table).
class TamituApp extends ConsumerWidget {
  const TamituApp({super.key});

  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
    for (final s in supported) {
      if (s.languageCode == device?.languageCode) return s;
    }
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(uiLanguageProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      locale: language == null ? null : Locale(language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
