import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Função PULAR
  void skipLogin() {
    // Apenas fecha a tela de login
    Navigator.pop(context);
  }

  //Função de Login com E-mail 
  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context); // Fecha a tela
    } on FirebaseAuthException catch (e) {
      debugPrint("Erro no login: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login: ${e.message}')),
        );
      }
    }
  }

  // Função de Criar Conta com E-mail
  Future<void> signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context); // Fecha a tela
    } on FirebaseAuthException catch (e) {
      debugPrint("Erro no cadastro: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no cadastro: ${e.message}')),
        );
      }
    }
  }

  //  Função de Login com GOOGLE 
  Future<void> signInWithGoogle() async {
    // Google Sign-In (temporariamente desativado)
    // Funcionalidade reativada quando a integração estiver pronta
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aviso'),
        content: const Text(
          'Login com Google não está disponível no momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //  Botão de PULAR 
        leading: TextButton(
          onPressed: skipLogin,
          child: const Text(
            "Pular",
            style: TextStyle(color: Colors.black87), // Ajuste a cor
          ),
        ),
        title: const Text("Crie sua Conta"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //  Botão LOGIN COM GOOGLE 
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, size: 28), // Ícone do Google
              label: const Text("Entrar com Google"),
              onPressed: signInWithGoogle,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40), // Ocupa a largura
              ),
            ),
            const SizedBox(height: 20),
            const Text("Ou use seu e-mail:"),
            const SizedBox(height: 20),

            // Campo de E-mail
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-mail"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),

            // Campo de Senha
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Senha"),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Botão de Entrar
            ElevatedButton(
              onPressed: signIn,
              child: const Text("Entrar com E-mail"),
            ),
            
            // Botão de Criar Conta
            TextButton(
              onPressed: signUp,
              child: const Text("Não tenho conta. Criar uma com e-mail."),
            ),
          ],
        ),
      ),
    );
  }
}