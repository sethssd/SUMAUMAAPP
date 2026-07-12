import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../utils/app_theme.dart';
import '../../screens/detail_screen.dart';

/// Carrossel horizontal de cards compactos com as N plantas mais recentes.
class RecentesCarousel extends StatelessWidget {
  final List<PlantModel> plantas;
  final String title;

  const RecentesCarousel({
    super.key,
    required this.plantas,
    this.title = 'ADICIONADOS RECENTEMENTE',
  });

  @override
  Widget build(BuildContext context) {
    if (plantas.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cabeçalho ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: SumaColors.greenSage,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white70 : SumaColors.greenDeep,
                ),
              ),
            ],
          ),
        ),

        // ── Cards horizontais ─────────────────────────────────
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plantas.length,
            itemBuilder: (context, index) {
              final planta = plantas[index];
              return _RecenteCard(plant: planta, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _RecenteCard extends StatelessWidget {
  final PlantModel plant;
  final bool isDark;

  const _RecenteCard({required this.plant, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(plantaId: plant.id)),
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? SumaColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  plant.imagemUrl.isNotEmpty
                      ? Image.network(
                          plant.imagemUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: SumaColors.greenDeep.withValues(alpha: 0.4),
                            child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 32),
                          ),
                        )
                      : Container(
                          color: SumaColors.greenDeep.withValues(alpha: 0.4),
                          child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 32),
                        ),
                  // Badge "Novo"
                  if (_isRecent(plant.dataCriacao))
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SumaColors.greenBright,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NOVO',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Texto
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (plant.nomeCientifico.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.nomeCientifico,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: SumaColors.greenBright,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isRecent(DateTime? date) {
    if (date == null) return false;
    return DateTime.now().difference(date).inDays <= 14;
  }
}
