import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

/// Tela de cadastro público do Sumaúma Biodata.
/// Campos: Primeiro Nome, Sobrenome, E-mail, Senha, Confirmar Senha.
class PublicSignUpScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const PublicSignUpScreen({super.key, this.onSuccess});

  @override
  State<PublicSignUpScreen> createState() => _PublicSignUpScreenState();
}

class _PublicSignUpScreenState extends State<PublicSignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  void _setError(String? msg) {
    if (mounted) setState(() => _errorMsg = msg);
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está sendo usado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail não habilitado.';
      default:
        return 'Erro ao criar conta. Tente novamente.';
    }
  }

  void _handleSuccess() {
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else if (mounted) {
      // Volta até a raiz (HomeScreen) e descarta login + signup
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signUp() async {
    _setError(null);
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      final cred = await AuthService().signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      );
      if (cred != null) _handleSuccess();
    } on FirebaseAuthException catch (e) {
      _setError(_authError(e.code));
    } finally {
      _setLoading(false);
    }
  }

  // ── Social sign-up ────────────────────────────────────────

  Future<void> _signUpWithGoogle() async {
    _setError(null);
    _setLoading(true);
    try {
      final cred = await AuthService().signInWithGoogle();
      if (cred != null) _handleSuccess();
    } catch (_) {
      _setError('Não foi possível entrar com o Google.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signUpWithApple() async {
    _setError(null);
    _setLoading(true);
    try {
      final cred = await AuthService().signInWithApple();
      if (cred != null) _handleSuccess();
    } catch (_) {
      _setError('Não foi possível entrar com a Apple.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signUpWithFacebook() async {
    _setError(null);
    _setLoading(true);
    try {
      final cred = await AuthService().signInWithFacebook();
      if (cred != null) _handleSuccess();
    } catch (_) {
      _setError('Não foi possível entrar com o Facebook.');
    } finally {
      _setLoading(false);
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: const Color(0xFF2B3A30),
      body: Stack(
        children: [
          // ── Background Watermark ──────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'icons/ico-branco.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          
          // ── Conteúdo Principal ────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // ── Título ─────────────────────────────────────
                      const Center(
                        child: Text(
                          'Cadastro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ── Formulário ─────────────────────────────────

                      // Primeiro Nome
                      _CustomTextField(
                        controller: _firstNameCtrl,
                        label: 'Primeiro Nome',
                        hint: 'Leonardo',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Sobrenome
                      _CustomTextField(
                        controller: _lastNameCtrl,
                        label: 'Sobrenome',
                        hint: 'Ferreira',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // E-mail
                      _CustomTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'sumauma@gmail.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Senha
                      _CustomTextField(
                        controller: _passwordCtrl,
                        label: 'Senha',
                        hint: 'Min 8 caracteres',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe a senha';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirmar senha
                      _CustomTextField(
                        controller: _confirmCtrl,
                        label: 'Confirmar Senha',
                        hint: 'Min 8 caracteres',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirme a senha';
                          if (v != _passwordCtrl.text) return 'As senhas não coincidem';
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // ── Mensagem de erro ───────────────────────────
                      if (_errorMsg != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 32),

                      // ── Botão Entrar ─────────────────────────
                      _PrimaryButton(
                        label: 'Entrar',
                        isLoading: _isLoading,
                        onPressed: _signUp,
                      ),

                      const SizedBox(height: 32),

                      // ── Botões sociais ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIconButton(
                            iconPath: 'icons/apple_logo.png', // Fallback abaixo
                            icon: Icons.apple_rounded,
                            onPressed: _isLoading ? null : _signUpWithApple,
                          ),
                          const SizedBox(width: 16),
                          _SocialIconButton(
                            iconPath: 'icons/google50x50.png',
                            onPressed: _isLoading ? null : _signUpWithGoogle,
                          ),
                          const SizedBox(width: 16),
                          _SocialIconButton(
                            facebookIcon: true,
                            onPressed: _isLoading ? null : _signUpWithFacebook,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Link já tem conta ─────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Column(
                          children: [
                            Text(
                              'Já tem uma conta?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Entre aqui',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

/// Campo de texto customizado: label acima, hint na linha, borda inferior branca.
class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone
        Row(
          children: [
            Icon(prefixIcon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Campo
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: false,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD9D9D9), // Cinza claro do mockup
          foregroundColor: const Color(0xFF5A5A5A),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF5A5A5A),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final String? iconPath;
  final IconData? icon;
  final bool facebookIcon;
  final VoidCallback? onPressed;

  const _SocialIconButton({
    this.iconPath,
    this.icon,
    this.facebookIcon = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF3B4A40), // Verde um pouco mais claro que o fundo
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _buildIcon(),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (iconPath != null) {
      return Image.asset(
        iconPath!, 
        width: 36, 
        height: 36,
        errorBuilder: (_, __, ___) => Icon(icon ?? Icons.star, size: 36, color: Colors.white),
      );
    } else if (facebookIcon) {
      return const Icon(Icons.facebook_rounded, size: 40, color: Color(0xFF1877F2));
    } else if (icon != null) {
      return Icon(icon, size: 40, color: Colors.white);
    }
    return const SizedBox.shrink();
  }
}
