import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/public_login_screen.dart';

/// AuthGate observa o stream de autenticação do Firebase e decide qual
/// tela mostrar: HomeScreen (autenticado) ou PublicLoginScreen (sem sessão).
/// Não interfere no fluxo de AdminLoginScreen/roles já existente.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Aguardando a verificação inicial de sessão
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Usuário autenticado → vai para a Home
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Sem sessão → tela pública de login
        return const PublicLoginScreen();
      },
    );
  }
}
