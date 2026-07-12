import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../utils/app_theme.dart';
import '../../screens/detail_screen.dart';

/// Card de planta enriquecido com badges condicionais e botões de ação rápida.
///
/// Badges exibidos quando o campo correspondente não está vazio:
///   🔊 Áudio (audioUrl), 🧊 Modelo 3D (modelo3dUrl),
///   🔬 Artigos (referenciasCientificas não-vazio).
///
/// Botões de ação rápida:
///   "Resumo Científico" → abre DetailScreen na aba Científico.
///   "Saiba Mais" → abre DetailScreen na aba Geral.
class PlantCard extends StatelessWidget {
  final PlantModel plant;

  const PlantCard({super.key, required this.plant});

  void _openDetail(BuildContext context, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(plantaId: plant.id, initialTab: initialTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool hasAudio = plant.audioUrl.isNotEmpty;
    final bool hasModel3d = plant.modelo3dUrl.isNotEmpty;
    final bool hasArticles = plant.referenciasCientificas != null &&
        plant.referenciasCientificas!.isNotEmpty;

    return Card(
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      plant.imagemUrl.isNotEmpty
                          ? Image.network(
                              plant.imagemUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: SumaColors.greenDeep.withValues(alpha: 0.3),
                                child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 32),
                              ),
                            )
                          : Container(
                              color: SumaColors.greenDeep.withValues(alpha: 0.3),
                              child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 32),
                            ),
                      // Ícone 3D se existir
                      if (hasModel3d)
                        Positioned(
                          bottom: 3, right: 3,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.threesixty_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Conteúdo principal ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome + badges
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            plant.nome,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Badges compactos
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasAudio) _Badge(icon: Icons.volume_up_rounded, color: Colors.teal),
                            if (hasModel3d) _Badge(icon: Icons.view_in_ar_rounded, color: SumaColors.greenBright),
                            if (hasArticles) _Badge(icon: Icons.science_rounded, color: Colors.indigo),
                          ],
                        ),
                      ],
                    ),

                    // Nome científico
                    if (plant.nomeCientifico.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        plant.nomeCientifico,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: SumaColors.greenBright,
                        ),
                      ),
                    ],

                    // Categoria
                    if (plant.categoria.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _CategoryTag(label: plant.categoria, isDark: isDark),
                    ],

                    // Descrição curta
                    if (plant.descricaoCurta.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        plant.descricaoCurta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.55)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ── Botões rápidos ──────────────────────────
                    Row(
                      children: [
                        if (hasArticles) ...[
                          _QuickButton(
                            label: 'Resumo Científico',
                            icon: Icons.biotech_outlined,
                            color: Colors.indigo,
                            isDark: isDark,
                            onTap: () => _openDetail(context, initialTab: 1),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _QuickButton(
                          label: 'Saiba Mais',
                          icon: Icons.arrow_forward_rounded,
                          color: SumaColors.greenBright,
                          isDark: isDark,
                          onTap: () => _openDetail(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

/// Ícone circular colorido para áudio / 3D / artigos.
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Badge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}

/// Pílula de categoria.
class _CategoryTag extends StatelessWidget {
  final String label;
  final bool isDark;

  const _CategoryTag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: SumaColors.greenBright.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? SumaColors.greenSage : SumaColors.greenMid,
        ),
      ),
    );
  }
}

/// Botão de ação rápida compacto.
class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
