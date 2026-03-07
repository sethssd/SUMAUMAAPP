import 'package:flutter/material.dart';

/// Paleta de cores SUMAÚMA — baseada nos mockups botânicos.
class SumaColors {
  // Comum
  static const greenDeep = Color(0xFF1B4332);
  static const greenMid = Color(0xFF2D6A4F);
  static const greenBright = Color(0xFF40916C);
  static const greenSage = Color(0xFF74C69D);
  static const greenLight = Color(0xFFD8F3DC);
  static const greenPale = Color(0xFFF0FBF4);

  // Dark theme
  static const darkBg = Color(0xFF0A1A0F); // fundo principal
  static const darkCard = Color(0xFF111E14); // cards
  static const darkSurface = Color(
    0xFF162B1B,
  ); // superfície ligeiramente mais clara
  static const darkAppBar = Color(0xFF0D2213); // app bar dark
  static const darkDivider = Color(0xFF1E3524);
}

class AppTheme {
  // ── TEMA ESCURO (mockup botânico) ─────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SumaColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: SumaColors.greenBright,
      onPrimary: Colors.white,
      secondary: SumaColors.greenSage,
      onSecondary: SumaColors.darkBg,
      surface: SumaColors.darkCard,
      onSurface: Colors.white,
      surfaceContainerHighest: SumaColors.darkSurface,
      outline: SumaColors.darkDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SumaColors.darkAppBar,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      color: SumaColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: SumaColors.darkCard),
    listTileTheme: const ListTileThemeData(
      iconColor: SumaColors.greenBright,
      textColor: Colors.white,
      subtitleTextStyle: TextStyle(color: SumaColors.greenSage),
    ),
    dividerTheme: const DividerThemeData(
      color: SumaColors.darkDivider,
      thickness: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SumaColors.greenBright,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SumaColors.darkSurface,
      labelStyle: const TextStyle(color: SumaColors.greenSage),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.greenBright, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SumaColors.darkSurface,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? SumaColors.greenBright : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? SumaColors.greenMid : null,
      ),
    ),
  );

  // ── TEMA CLARO (mockup branco botânico) ───────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF6FBF7),
    colorScheme: const ColorScheme.light(
      primary: SumaColors.greenMid,
      onPrimary: Colors.white,
      secondary: SumaColors.greenBright,
      surface: Colors.white,
      onSurface: Color(0xFF1A1A2E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SumaColors.greenMid,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: SumaColors.greenMid.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    listTileTheme: const ListTileThemeData(
      iconColor: SumaColors.greenMid,
      textColor: Color(0xFF1A1A2E),
      subtitleTextStyle: TextStyle(color: SumaColors.greenBright),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0EDE4),
      thickness: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SumaColors.greenMid,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0FBF4),
      labelStyle: const TextStyle(color: SumaColors.greenMid),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB7DFC6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB7DFC6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.greenMid, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SumaColors.greenDeep,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
