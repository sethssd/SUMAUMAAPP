import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum NivelSeguranca { atencao, cuidadoSeguro, cuidadoPerigo, avisoGeral }

extension NivelSegurancaExtension on NivelSeguranca {
  Color get cor {
    switch (this) {
      case NivelSeguranca.atencao:
        return Colors.orange;
      case NivelSeguranca.cuidadoSeguro:
        return Colors.green;
      case NivelSeguranca.cuidadoPerigo:
        return Colors.red;
      case NivelSeguranca.avisoGeral:
        return Colors.blue;
    }
  }

  String get rotulo {
    switch (this) {
      case NivelSeguranca.atencao:
        return 'Atenção';
      case NivelSeguranca.cuidadoSeguro:
        return 'Cuidado (uso seguro)';
      case NivelSeguranca.cuidadoPerigo:
        return 'Cuidado (perigo)';
      case NivelSeguranca.avisoGeral:
        return 'Aviso Geral';
    }
  }
}

class SafetyLegend extends StatelessWidget {
  const SafetyLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legenda de Segurança',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NivelSeguranca.values.map((nivel) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: nivel.cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    nivel.rotulo,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class CuidadoAvancadoCard extends StatefulWidget {
  final Map<String, dynamic> cuidado;

  const CuidadoAvancadoCard({super.key, required this.cuidado});

  @override
  State<CuidadoAvancadoCard> createState() => _CuidadoAvancadoCardState();
}

class _CuidadoAvancadoCardState extends State<CuidadoAvancadoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final nivelStr = widget.cuidado['nivel'] as String? ?? 'avisoGeral';
    final nivel = NivelSeguranca.values.firstWhere(
      (e) => e.name == nivelStr,
      orElse: () => NivelSeguranca.avisoGeral,
    );
    final descricao = widget.cuidado['descricao'] as String? ?? '';
    final doseRecomendada = widget.cuidado['doseRecomendada'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: nivel.cor.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: nivel.cor),
            title: Text(
              descricao,
              style: const TextStyle(fontSize: 14),
            ),
            trailing: doseRecomendada != null && doseRecomendada.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: nivel.cor,
                    ),
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                  )
                : null,
          ),
          if (doseRecomendada != null && doseRecomendada.isNotEmpty)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nivel.cor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_information,
                                  size: 16, color: nivel.cor),
                              const SizedBox(width: 8),
                              Text(
                                'A Dose Certa',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: nivel.cor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doseRecomendada,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
