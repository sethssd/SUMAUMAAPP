import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'firebase_options.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';
import 'utils/auth_gate.dart';
import 'utils/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: AppConstants.audioChannelId,
        androidNotificationChannelName: 'Reprodução de Áudio',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/launcher_icon',
      );
    } catch (_) {}
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Sumaúma',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // AuthGate decide entre PublicLoginScreen e HomeScreen
          // com base no estado de autenticação do Firebase.
          home: const AuthGate(),
        );
      },
    );
  }
}
