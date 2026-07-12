import 'package:flutter/material.dart';

class LocationReviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> locais;

  const LocationReviewCard({super.key, required this.locais});

  @override
  Widget build(BuildContext context) {
    if (locais.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Onde Encontrar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        ...locais.map((local) {
          final nomeLocal = local['nomeLocal'] as String? ?? 'Desconhecido';
          final endereco = local['endereco'] as String? ?? '';
          final avaliacaoMedia = (local['avaliacaoMedia'] as num?)?.toDouble() ?? 0.0;
          final reviewsRaw = local['reviews'] as List<dynamic>? ?? [];
          final reviews = reviewsRaw.map((e) => e as Map<String, dynamic>).toList();

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.green),
              ),
              title: Text(
                nomeLocal,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endereco,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        avaliacaoMedia.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' (${reviews.length} avaliações)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                if (reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nenhuma avaliação ainda.'),
                  )
                else
                  ...reviews.map((review) {
                    final autor = review['autor'] as String? ?? 'Anônimo';
                    final texto = review['texto'] as String? ?? '';
                    final nota = (review['nota'] as num?)?.toDouble() ?? 0.0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          autor.isNotEmpty ? autor[0].toUpperCase() : 'A',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              autor,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < nota.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(texto),
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
