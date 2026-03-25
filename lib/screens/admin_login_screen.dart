import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIN ─────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('Preencha e-mail e senha.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user!;

      // Garante que todo usuário que loga tenha um documento no Firestore.
      // Isso faz com que contas criadas diretamente no Firebase Auth também
      // apareçam na tela de Gerenciar Admins após o primeiro login.
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'nome': user.displayName ?? user.email?.split('@').first ?? '',
          'role': 'usuario',
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── CRIAR CONTA ───────────────────────────────────────────
  Future<void> _showCreateAccountDialog() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Criar Conta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                    helperText: 'Mínimo 6 caracteres',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'O cargo será definido pelo Super Admin.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (emailCtrl.text.trim().isEmpty ||
                    passwordCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha e-mail e senha.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _createAccount(
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                );
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    setState(() => _isLoading = true);
    try {
      // 1. Cria o usuário no Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // 2. Atualiza nome de exibição no Auth
      if (name.isNotEmpty) {
        await credential.user!.updateDisplayName(name);
      }

      // 3. Salva com role 'usuario' — super admin promove depois
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nome': name.isNotEmpty ? name : email.split('@').first,
        'role': 'usuario',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Conta criada para $email'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e.code));
    } catch (e) {
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── HELPERS ───────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde.';
      default:
        return 'Erro de autenticação: $code';
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Acesso Restrito")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone de cadeado
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              "Área do Administrador",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Campo E-mail
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-mail",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Campo Senha
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Senha",
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 24),

            // Botão Entrar
            FilledButton.icon(
              onPressed: _isLoading ? null : _signIn,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: const Text("Entrar"),
            ),
            const SizedBox(height: 12),

            // Botão Criar Conta (outline, menos destaque)
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _showCreateAccountDialog,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text("Criar Conta"),
            ),
            const SizedBox(height: 16),
            
            // Botão Entrar com o Google
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Image.asset(
                'icons/icons8-google-logo-48.png',
                height: 24,
              ),
              label: const Text(
                "Entrar com o Google",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      final userCred = await AuthService().signInWithGoogle();
                      if (mounted) setState(() => _isLoading = false);

                      if (userCred != null && mounted) {
                        Navigator.pop(context); // Fechar tela de login e voltar logado
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
