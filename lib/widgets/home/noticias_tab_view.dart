import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/destaque_model.dart';
import '../../screens/detail_screen.dart';
import '../../utils/app_theme.dart';

/// Aba "Notícias" — Canal informativo sobre acontecimentos relacionados às
/// plantas e ao meio ambiente na Amazônia. Ao tocar em uma notícia, redireciona
/// para a planta vinculada do catálogo ou para a postagem externa.
class NoticiasTabView extends StatelessWidget {
  final List<DestaqueModel> destaques;
  final Future<void> Function()? onRefresh;

  const NoticiasTabView({
    super.key,
    required this.destaques,
    this.onRefresh,
  });

  Future<void> _openPostagem(BuildContext context, DestaqueModel d) async {
    final plantaId = d.plantaId.trim();
    if (plantaId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(plantaId: plantaId),
        ),
      );
      return;
    }

    final trimmed = d.link.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta postagem é informativa e não possui link externo vinculado.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final normalized =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir a postagem: $trimmed')),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (destaques.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.newspaper_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma notícia publicada no momento.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final listContent = ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      itemCount: destaques.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notícias e Destaques',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? SumaColors.greenSage : SumaColors.greenAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fique por dentro do que está acontecendo em relação às plantas, pesquisas e preservação na Amazônia. Toque em uma matéria para acessar o conteúdo completo.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        final d = destaques[index - 1];
        final dateStr = _formatDate(d.dataPublicacao);
        final hasPlanta = d.plantaId.trim().isNotEmpty;

        return GestureDetector(
          onTap: () => _openPostagem(context, d),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark ? SumaGradients.darkCard : SumaGradients.destaqueCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem da postagem
                if (d.imagemUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 185,
                      width: double.infinity,
                      child: Image.network(
                        d.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SumaColors.greenDeep,
                          child: const Icon(
                            Icons.newspaper_rounded,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Título
                Text(
                  d.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),

                if (d.resumo.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    d.resumo,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasPlanta ? 'Ver planta vinculada' : 'Ver postagem',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            hasPlanta ? Icons.eco_rounded : Icons.open_in_new_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: listContent,
      );
    }
    return listContent;
  }
}
