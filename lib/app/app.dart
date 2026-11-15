import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'home_screen.dart';

/// Root widget. Polish is the default locale (ADR-0006).
class TamituApp extends StatelessWidget {
  const TamituApp({super.key});

  /// Default language is Polish: any unsupported device locale falls back to
  /// `pl` (the ARB template is `app_en.arb` because gen_l10n defaults are used).
  static Locale _resolveLocale(Locale? locale, Iterable<Locale> supported) {
    for (final s in supported) {
      if (s.languageCode == locale?.languageCode) return s;
    }
    return const Locale('pl');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      home: const HomeScreen(),
    );
  }
}
