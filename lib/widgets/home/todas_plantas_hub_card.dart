import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../screens/detail_screen.dart';
import '../../utils/app_theme.dart';

/// Dados de uma pílula (badge) de aspecto da planta.
class PlantPillData {
  final String label;
  final IconData icon;
  final int targetTab;

  const PlantPillData({
    required this.label,
    required this.icon,
    this.targetTab = 0,
  });
}

/// Constrói a lista de pílulas para uma planta combinando regras automáticas
/// e tags manuais (`aspectosUso`).
List<PlantPillData> buildPlantPills(
  PlantModel plant, {
  bool includeResumo = false,
  bool includeManualAspects = true,
}) {
  final List<PlantPillData> pills = [];

  if (plant.hasAudio) {
    pills.add(const PlantPillData(
      label: 'Áudio',
      icon: Icons.graphic_eq_rounded,
      targetTab: 0,
    ));
  }
  if (plant.hasModel3d) {
    pills.add(const PlantPillData(
      label: 'Modelo 3D',
      icon: Icons.view_in_ar_rounded,
      targetTab: 0,
    ));
  }
  if (plant.hasArticles) {
    pills.add(const PlantPillData(
      label: 'Artigos Científicos',
      icon: Icons.menu_book_rounded,
      targetTab: 2,
    ));
  }
  if (includeResumo && plant.hasResumo) {
    pills.add(const PlantPillData(
      label: 'Resumo',
      icon: Icons.article_outlined,
      targetTab: 0,
    ));
  }
  if (plant.hasCientifico) {
    pills.add(const PlantPillData(
      label: 'Científico',
      icon: Icons.science_rounded,
      targetTab: 1,
    ));
  }
  if (plant.hasVisitacao) {
    pills.add(const PlantPillData(
      label: 'Visitação',
      icon: Icons.location_on_rounded,
      targetTab: 0,
    ));
  }

  if (includeManualAspects) {
    for (final rawAspect in plant.aspectosUso) {
      final aspect = rawAspect.trim();
      if (aspect.isEmpty) continue;
      pills.add(PlantPillData(
        label: aspect,
        icon: _iconForManualAspect(aspect),
        targetTab: 0,
      ));
    }
  }

  return pills;
}

IconData _iconForManualAspect(String aspect) {
  final lower = aspect.toLowerCase();
  if (lower.contains('chá') || lower.contains('cha')) {
    return Icons.emoji_food_beverage_rounded;
  }
  if (lower.contains('suco')) return Icons.local_drink_rounded;
  if (lower.contains('banho')) return Icons.bathtub_outlined;
  if (lower.contains('óleo') || lower.contains('oleo')) {
    return Icons.water_drop_rounded;
  }
  if (lower.contains('fruto')) return Icons.spa_rounded;
  if (lower.contains('semente')) return Icons.grain_rounded;
  if (lower.contains('folha')) return Icons.eco_rounded;
  if (lower.contains('casca') || lower.contains('tronco')) {
    return Icons.park_rounded;
  }
  if (lower.contains('raiz')) return Icons.grass_rounded;
  return Icons.local_florist_rounded;
}

/// Pílula visual estilizada conforme o mockup do Hub Inicial.
class PlantAspectPill extends StatelessWidget {
  final PlantPillData data;
  final VoidCallback? onTap;

  const PlantAspectPill({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E5231) : const Color(0xFF76D38B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2EA055) : const Color(0xFF147A2E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                size: 11,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0A3815),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloco "Toda as Plantas" exibido na Home com prévia expansível ("Principais Aspectos")
/// e botão "Ver todas as plantas >" no rodapé.
class TodasPlantasHubCard extends StatefulWidget {
  final List<PlantModel> plantas;
  final VoidCallback onSeeAllTap;

  const TodasPlantasHubCard({
    super.key,
    required this.plantas,
    required this.onSeeAllTap,
  });

  @override
  State<TodasPlantasHubCard> createState() => _TodasPlantasHubCardState();
}

class _TodasPlantasHubCardState extends State<TodasPlantasHubCard> {
  // Primeiro item inicia expandido, assim como o "Limãozinho" no protótipo.
  final Set<int> _expandedIndices = {0};

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  void _openDetail(BuildContext context, String plantaId, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(plantaId: plantaId, initialTab: initialTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plantas.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewPlants = widget.plantas.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F3D1E) : const Color(0xFF007A1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho verde "Toda as Plantas"
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 18, 22, 16),
            child: Text(
              'Toda as\nPlantas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: Colors.white,
              ),
            ),
          ),

          // Corpo branco arredondado com a lista de prévia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: isDark ? SumaColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (int i = 0; i < previewPlants.length; i++) ...[
                  _buildPlantPreviewItem(
                    context,
                    plant: previewPlants[i],
                    index: i,
                    isExpanded: _expandedIndices.contains(i),
                    isLastPreview: i == previewPlants.length - 1 && previewPlants.length >= 3,
                    isDark: isDark,
                  ),
                  if (i < previewPlants.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? Colors.white12 : Colors.black26,
                      ),
                    ),
                ],
                const SizedBox(height: 18),

                // Botão "Ver todas as plantas >"
                InkWell(
                  onTap: widget.onSeeAllTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver todas as\nplantas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: isDark ? SumaColors.greenSage : const Color(0xFF0A5C1A),
                            decoration: TextDecoration.underline,
                            decorationColor:
                                isDark ? SumaColors.greenSage : const Color(0xFF0A5C1A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 28,
                          color: isDark ? SumaColors.greenSage : const Color(0xFF0A5C1A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantPreviewItem(
    BuildContext context, {
    required PlantModel plant,
    required int index,
    required bool isExpanded,
    required bool isLastPreview,
    required bool isDark,
  }) {
    final pills = buildPlantPills(plant, includeResumo: false, includeManualAspects: true);
    final resumo = plant.resumoLimpo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openDetail(context, plant.id),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna esquerda: Nome + resumo + gatilho Principais Aspectos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.nome,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? SumaColors.greenSage : const Color(0xFF0A5C1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (resumo.isNotEmpty)
                      Text(
                        resumo,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.78)
                              : const Color(0xFF333333),
                        ),
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _toggleExpanded(index),
                      child: Opacity(
                        opacity: isLastPreview && !isExpanded ? 0.45 : 1.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Principais Aspectos',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark ? Colors.white60 : const Color(0xFF444444),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Foto à direita
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: plant.imagemUrl.isNotEmpty
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
                ),
              ),
            ],
          ),
        ),

        // Pílulas quando "Principais Aspectos" está expandido
        if (isExpanded && pills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pills
                .map(
                  (pill) => PlantAspectPill(
                    data: pill,
                    onTap: () => _openDetail(
                      context,
                      plant.id,
                      initialTab: pill.targetTab,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
