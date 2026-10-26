import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../screens/detail_screen.dart';
import '../../utils/app_theme.dart';

/// Card "Popular" — retângulo branco elevado exibindo as plantas populares
/// com miniaturas de cantos arredondados e nome centralizado abaixo.
class PopularPlantsRow extends StatelessWidget {
  final List<PlantModel> plantas;

  const PopularPlantsRow({
    super.key,
    required this.plantas,
  });

  @override
  Widget build(BuildContext context) {
    if (plantas.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? SumaColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plantas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final plant = plantas[index];
                return _PopularAvatar(plant: plant, isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularAvatar extends StatelessWidget {
  final PlantModel plant;
  final bool isDark;

  const _PopularAvatar({required this.plant, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(plantaId: plant.id)),
      ),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: plant.imagemUrl.isNotEmpty
                    ? Image.network(
                        plant.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SumaColors.greenAccent,
                          child: const Icon(Icons.eco, color: Colors.white54, size: 24),
                        ),
                      )
                    : Container(
                        color: SumaColors.greenAccent,
                        child: const Icon(Icons.eco, color: Colors.white54, size: 24),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                plant.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
