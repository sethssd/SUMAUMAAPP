import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/account/botanical_header.dart';

/// Tela de Sugestões — fiel ao mockup "Sugestões Conta.pdf".
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _suggestionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _suggestionController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _suggestionController.removeListener(_onTextChanged);
    _suggestionController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  int get _wordCount {
    final text = _suggestionController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Future<void> _sendSuggestion() async {
    final text = _suggestionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escreva sua sugestão antes de enviar.')),
      );
      return;
    }
    if (_wordCount > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A sugestão deve ter no máximo 500 palavras.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('sugestoes').add({
        'texto': text,
        'uid': user?.uid ?? '',
        'email': user?.email ?? '',
        'nome': user?.displayName ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'lido': false,
      });

      _suggestionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obrigado! Sua sugestão foi enviada para nossa equipe.'),
            backgroundColor: kAccountGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar sugestão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : kAccountPageBg,
      body: Column(
        children: [
          const BotanicalAppBar(
            title: 'SUGESTÕES',
            uppercaseTitle: true,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner superior: "Ajude-nos a melhorar!" (fiel a Sugestões Conta.pdf)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? SumaColors.darkCard : const Color(0xFFF3EFFA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 68,
                          child: CustomPaint(
                            painter: _BotanicalBulbPainter(
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ajude-nos a melhorar!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF141414),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sugira plantas, informe erros ou envie ideias para nossa equipe.',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.32,
                                  color: isDark ? Colors.white70 : const Color(0xFF262626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Caixa de texto branca arredondada
                  Container(
                    height: 168,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? SumaColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC),
                      ),
                    ),
                    child: TextField(
                      controller: _suggestionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Deixe sua sugestão...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white38 : const Color(0xFF8C8C8C),
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Contador de palavras alinhado à direita
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Palavras: $_wordCount / 500',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: _wordCount > 500
                            ? Colors.red
                            : (isDark ? Colors.white60 : const Color(0xFF7A7A7A)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Botão verde em pílula "Enviar"
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccountGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enviar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desenha o ícone de lâmpada com árvore botânica interna fiel ao PDF "Sugestões Conta.pdf".
class _BotanicalBulbPainter extends CustomPainter {
  final Color color;
  const _BotanicalBulbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final r = size.width * 0.27;

    // Raios superiores ao redor da lâmpada
    const rayAngles = [-2.55, -2.1, -1.57, -1.04, -0.59];
    for (final a in rayAngles) {
      final p1 = Offset(cx + (r + 5) * _cos(a), cy + (r + 5) * _sin(a));
      final p2 = Offset(cx + (r + 10) * _cos(a), cy + (r + 10) * _sin(a));
      canvas.drawLine(p1, p2, stroke);
    }

    // Bulbo da lâmpada
    final bulbPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        2.35,
        4.72,
      )
      ..quadraticBezierTo(cx + r * 0.65, cy + r * 1.15, cx + r * 0.48, cy + r * 1.45)
      ..lineTo(cx - r * 0.48, cy + r * 1.45)
      ..quadraticBezierTo(cx - r * 0.65, cy + r * 1.15, cx - r * 0.70, cy + r * 0.70);
    canvas.drawPath(bulbPath, stroke);

    // Base rosqueada da lâmpada
    final baseTop = cy + r * 1.55;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, baseTop + 3), width: r * 0.92, height: 4.5),
        const Radius.circular(2.5),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, baseTop + 9), width: r * 0.72, height: 4.2),
        const Radius.circular(2.5),
      ),
      stroke,
    );

    // Árvore botânica estilizada no interior do bulbo
    final trunkBottom = cy + r * 1.42;
    final trunkTop = cy - r * 0.42;
    canvas.drawLine(Offset(cx, trunkBottom), Offset(cx, trunkTop), stroke);

    // Ramos simétricos da árvore
    canvas.drawLine(Offset(cx, cy - r * 0.05), Offset(cx - r * 0.45, cy - r * 0.38), stroke);
    canvas.drawLine(Offset(cx, cy - r * 0.05), Offset(cx + r * 0.45, cy - r * 0.38), stroke);
    canvas.drawLine(Offset(cx, cy + r * 0.32), Offset(cx - r * 0.38, cy + r * 0.02), stroke);
    canvas.drawLine(Offset(cx, cy + r * 0.32), Offset(cx + r * 0.38, cy + r * 0.02), stroke);
  }

  double _cos(double rad) {
    // Série rápida ou dart:math
    return _Trig.cos(rad);
  }

  double _sin(double rad) {
    return _Trig.sin(rad);
  }

  @override
  bool shouldRepaint(covariant _BotanicalBulbPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Trig {
  static double sin(double x) {
    // Normaliza em [-pi, pi]
    double a = x;
    final x2 = a * a;
    return a * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  static double cos(double x) {
    return sin(x + 1.57079632679);
  }
}
