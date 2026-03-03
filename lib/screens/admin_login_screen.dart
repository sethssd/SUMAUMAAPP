import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Função de Login (só E-mail/Senha)
  Future<void> signInAdmin() async {
    try {
      // 1. Faz o login no Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. MUDANÇA AQUI:
      //    Se o login deu certo, APENAS fechamos a tela de login.
      if (mounted) {
        Navigator.pop(context); // Fecha a tela de login e volta para a HomeScreen
      }

    } on FirebaseAuthException catch (e) {
      // Mostra um erro se a senha/email estiver errado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de Admin: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acesso Restrito")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Área do Administrador",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-mail de Admin"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Senha"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signInAdmin,
              child: const Text("Entrar"),
            ),
            // NÃO HÁ BOTÃO DE "CRIAR CONTA" ainda.
          ],
        ),
      ),
    );
  }
}
