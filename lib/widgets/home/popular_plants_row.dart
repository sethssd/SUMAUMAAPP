import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../screens/detail_screen.dart';

/// Linha horizontal "Popular" — avatares circulares com nome abaixo.
/// Exibida no topo verde da Home, logo após a barra de busca.
class PopularPlantsRow extends StatelessWidget {
  final List<PlantModel> plantas;
  final VoidCallback? onShowAll;

  const PopularPlantsRow({
    super.key,
    required this.plantas,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    if (plantas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título + "Mostrar Tudo"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Popular',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (onShowAll != null)
                GestureDetector(
                  onTap: onShowAll,
                  child: Text(
                    'Mostrar\nTudo',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Avatares
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plantas.length,
            itemBuilder: (context, index) {
              final plant = plantas[index];
              return _PopularAvatar(plant: plant);
            },
          ),
        ),
      ],
    );
  }
}

class _PopularAvatar extends StatelessWidget {
  final PlantModel plant;

  const _PopularAvatar({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(plantaId: plant.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // Avatar circular
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: plant.imagemUrl.isNotEmpty
                    ? Image.network(
                        plant.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF2D6A4F),
                          child: const Icon(Icons.eco, color: Colors.white54, size: 24),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF2D6A4F),
                        child: const Icon(Icons.eco, color: Colors.white54, size: 24),
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // Nome
            SizedBox(
              width: 64,
              child: Text(
                plant.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
