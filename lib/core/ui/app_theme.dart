import 'package:material_ui/material_ui.dart';

import 'app_icon.dart';
import 'tokens.dart';

/// Material 3 theme, brand A "Lazur" (design-system.md v0.3). Colour roles are written
/// out explicitly (no `ColorScheme.fromSeed`, no dynamic colour – UX3).
abstract final class AppTheme {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006A6A),
    onPrimary: Color(0xFFEEF4F3),
    primaryContainer: Color(0xFF9CF1F0),
    onPrimaryContainer: Color(0xFF002020),
    secondary: Color(0xFF4A6363),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFC4E2E1),
    onSecondaryContainer: Color(0xFF051F1F),
    tertiary: Color(0xFF8F4C38),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBD1),
    onTertiaryContainer: Color(0xFF3A0B01),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFE6EDEC),
    onSurface: Color(0xFF161D1D),
    onSurfaceVariant: Color(0xFF3F4948),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFDFE6E5),
    surfaceContainer: Color(0xFFDAE1E0),
    surfaceContainerHigh: Color(0xFFD5DCDB),
    surfaceContainerHighest: Color(0xFFDDE4E3),
    outline: Color(0xFF6F7979),
    outlineVariant: Color(0xFFBEC9C8),
    inverseSurface: Color(0xFF2B3231),
    onInverseSurface: Color(0xFFECF2F1),
    inversePrimary: Color(0xFF80D5D4),
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF80D5D4),
    onPrimary: Color(0xFF003737),
    primaryContainer: Color(0xFF004F4F),
    onPrimaryContainer: Color(0xFF9CF1F0),
    secondary: Color(0xFFB0CCCB),
    onSecondary: Color(0xFF1B3534),
    secondaryContainer: Color(0xFF324B4B),
    onSecondaryContainer: Color(0xFFCCE8E7),
    tertiary: Color(0xFFFFB5A0),
    onTertiary: Color(0xFF561F0F),
    tertiaryContainer: Color(0xFF723523),
    onTertiaryContainer: Color(0xFFFFDBD1),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0E1514),
    onSurface: Color(0xFFCFD6D5),
    onSurfaceVariant: Color(0xFFBEC9C8),
    surfaceContainerLowest: Color(0xFF090F0F),
    surfaceContainerLow: Color(0xFF161D1D),
    surfaceContainer: Color(0xFF1A2121),
    surfaceContainerHigh: Color(0xFF252B2B),
    surfaceContainerHighest: Color(0xFF303636),
    outline: Color(0xFF889392),
    outlineVariant: Color(0xFF3F4948),
    inverseSurface: Color(0xFFDDE4E3),
    onInverseSurface: Color(0xFF2B3231),
    inversePrimary: Color(0xFF006A6A),
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );

  static ThemeData lightTheme() => _build(light);

  static ThemeData darkTheme() => _build(dark);

  static ThemeData _build(ColorScheme scheme) {
    const pill = StadiumBorder();
    const minSize = Size(64, 40);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: pill, minimumSize: minSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: pill, minimumSize: minSize),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: pill, minimumSize: minSize),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 3,
        elevation: 0,
      ),
      // design-system.md pkt 8.1: back button icon replaced via the theme (ADR-0010 pkt 3).
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const AppIcon(AppIcons.back),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.m)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.xs)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.xl)),
        ),
      ),
    );
  }
}
