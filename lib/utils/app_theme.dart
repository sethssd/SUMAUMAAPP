import 'package:flutter/material.dart';

/// Paleta de cores SUMAÚMA — baseada nos mockups botânicos.
class SumaColors {
  // Comum
  static const greenDeep = Color(0xFF1B4332);
  static const greenMid = Color(0xFF7AB66E); // Verde da interface clara (#7AB66E)
  static const greenAccent = Color(0xFF7AB66E); // #7AB66E
  static const greenAccentDark = Color(0xFF5E9C52);
  static const greenAccentSoft = Color(0xFFE5F2E1);
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

  // Light theme tokens (limpos, elegantes e de alto contraste)
  static const lightBg = Color(0xFFF6F8F6);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFD5E2D8);
  static const lightBorderStrong = Color(0xFFB8CEBE);
  static const lightText = Color(0xFF132419);
  static const lightTextSecondary = Color(0xFF43584A);
  static const lightTextMuted = Color(0xFF687D6F);
}

/// Gradientes fiéis extraídos do PDF do projeto botânico (Hub Inicial).
class SumaGradients {
  /// Gradiente da barra de pesquisa inline (diagonal suave, verde claro a verde profundo)
  static const searchBar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7AB66E), Color(0xFF26592C)],
  );

  /// Gradiente do botão de filtro quando filtros estão ativos
  static const filterActive = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E9C52), Color(0xFF1B4324)],
  );

  /// Gradiente do cabeçalho de "Todas as Plantas" (horizontal com desvanecimento suave)
  static const todasPlantasCard = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.55, 1.0],
    colors: [
      Color(0xFF7AB66E),
      Color(0xFF68A75D),
      Color(0xFF235A2F),
    ],
  );

  /// Gradiente do card de Destaques
  static const destaqueCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [
      Color(0xFF7AB66E),
      Color(0xFF68A75D),
      Color(0xFF235A2F),
    ],
  );

  /// Gradiente da grande seção "Adicionados" (diagonal ampla até o verde floresta profundo)
  static const adicionadosSection = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7AB66E),
      Color(0xFF1E5228),
    ],
  );

  /// Gradiente das pílulas e tags de aspectos botânicos (horizontal da esquerda para a direita)
  static const aspectPill = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF7AB66E),
      Color(0xFF245F30),
    ],
  );

  /// Gradiente do círculo flutuante ativo da barra de navegação em onda
  static const bottomNavActiveCircle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF7AB66E),
      Color(0xFF458C4B),
    ],
  );

  // Versões dark mode
  static const darkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A4D28), Color(0xFF0D2815)],
  );

  static const darkPill = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF245F30), Color(0xFF122F18)],
  );
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
    scaffoldBackgroundColor: SumaColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: SumaColors.greenAccent,
      onPrimary: Colors.white,
      secondary: SumaColors.greenBright,
      surface: SumaColors.lightSurface,
      onSurface: SumaColors.lightText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SumaColors.greenAccent,
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
      shadowColor: SumaColors.greenAccent.withValues(alpha: 0.10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    listTileTheme: const ListTileThemeData(
      iconColor: SumaColors.greenAccent,
      textColor: SumaColors.lightText,
      subtitleTextStyle: TextStyle(color: SumaColors.greenAccent),
    ),
    dividerTheme: const DividerThemeData(
      color: SumaColors.lightBorder,
      thickness: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SumaColors.greenAccent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEFF4F0),
      labelStyle: const TextStyle(color: SumaColors.greenAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.lightBorderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SumaColors.greenAccent, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SumaColors.greenAccent,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
