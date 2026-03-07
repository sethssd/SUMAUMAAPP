import 'package:flutter/material.dart';

/// Controla o tema do app globalmente via ValueNotifier.
/// Padrão: ThemeMode.system (segue o sistema operacional).
final themeController = ValueNotifier<ThemeMode>(ThemeMode.system);

/// Alterna entre claro → escuro → sistema → claro → ...
void cycleTheme() {
  switch (themeController.value) {
    case ThemeMode.system:
      themeController.value = ThemeMode.light;
      break;
    case ThemeMode.light:
      themeController.value = ThemeMode.dark;
      break;
    case ThemeMode.dark:
      themeController.value = ThemeMode.system;
      break;
  }
}

/// Retorna o ícone correspondente ao modo atual.
IconData themeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode_rounded;
    case ThemeMode.dark:
      return Icons.dark_mode_rounded;
    case ThemeMode.system:
      return Icons.brightness_auto_rounded;
  }
}

/// Retorna o label correspondente ao modo atual.
String themeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Tema: Claro';
    case ThemeMode.dark:
      return 'Tema: Escuro';
    case ThemeMode.system:
      return 'Tema: Sistema';
  }
}
