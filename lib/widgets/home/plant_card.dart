import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../utils/app_theme.dart';
import '../../screens/detail_screen.dart';
import 'todas_plantas_hub_card.dart';

/// Card de planta enriquecido com pílulas automáticas/manuais e botões de ação rápida.
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
    final hasModel3d = plant.hasModel3d;
    final hasCientifico = plant.hasCientifico || plant.hasArticles;
    final resumo = plant.resumoLimpo;
    final pills = buildPlantPills(plant, includeResumo: false, includeManualAspects: true);

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
                  width: 82,
                  height: 82,
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
                    // Nome + categoria
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            plant.nome,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : SumaColors.lightText,
                            ),
                          ),
                        ),
                        if (plant.categoria.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CategoryTag(label: plant.categoria, isDark: isDark),
                        ],
                      ],
                    ),

                    // Nome científico
                    if (plant.nomeCientifico.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        plant.nomeCientifico,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: SumaColors.greenBright,
                        ),
                      ),
                    ],

                    // Descrição limpa (sem HTML)
                    if (resumo.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        resumo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],

                    // Pílulas de aspectos
                    if (pills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: pills
                            .map(
                              (pill) => PlantAspectPill(
                                data: pill,
                                onTap: () => _openDetail(
                                  context,
                                  initialTab: pill.targetTab,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ── Botões rápidos ──────────────────────────
                    Row(
                      children: [
                        if (hasCientifico) ...[
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
