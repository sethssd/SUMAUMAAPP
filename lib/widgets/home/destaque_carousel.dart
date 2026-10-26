import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/destaque_model.dart';
import '../../screens/detail_screen.dart';
import '../../utils/app_theme.dart';

/// Carrossel horizontal "Destaques" com animação de escala ao deslizar:
/// começa alinhado à esquerda em tamanho total enquanto o próximo card à direita
/// aparece menor; ao arrastar para o lado, o card que sai diminui suavemente e o
/// que entra cresce até o tamanho principal.
class DestaqueCarousel extends StatefulWidget {
  final List<DestaqueModel> destaques;

  const DestaqueCarousel({super.key, required this.destaques});

  @override
  State<DestaqueCarousel> createState() => _DestaqueCarouselState();
}

class _DestaqueCarouselState extends State<DestaqueCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.76,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openDestaque(BuildContext context, DestaqueModel d) async {
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
          SnackBar(content: Text('Não foi possível abrir o link: $trimmed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destaques.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Text(
            'Destaques',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? SumaColors.greenSage : SumaColors.greenAccent,
            ),
          ),
        ),
        SizedBox(
          height: 375,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              clipBehavior: Clip.none,
              itemCount: widget.destaques.length,
              itemBuilder: (context, index) {
                final d = widget.destaques[index];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double currentPage = 0.0;
                    if (_pageController.hasClients &&
                        _pageController.position.haveDimensions) {
                      currentPage =
                          _pageController.page ?? _pageController.initialPage.toDouble();
                    }
                    final distance = (currentPage - index).abs().clamp(0.0, 1.0);
                    // O card ativo fica em escala 1.0; os adjacentes ficam menores (0.87)
                    final scale = 1.0 - (distance * 0.13);
                    final verticalPadding = distance * 22.0;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: 14,
                        top: verticalPadding,
                        bottom: verticalPadding,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.centerLeft,
                        child: child,
                      ),
                    );
                  },
                  child: _DestaqueCard(
                    destaque: d,
                    isDark: isDark,
                    onTap: () => _openDestaque(context, d),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DestaqueCard extends StatelessWidget {
  final DestaqueModel destaque;
  final bool isDark;
  final VoidCallback onTap;

  const _DestaqueCard({
    required this.destaque,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isDark ? SumaGradients.darkCard : SumaGradients.destaqueCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem superior com cantos arredondados
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 152,
                width: double.infinity,
                child: destaque.imagemUrl.isNotEmpty
                    ? Image.network(
                        destaque.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SumaColors.greenDeep,
                          child: const Icon(
                            Icons.newspaper_rounded,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: SumaColors.greenDeep,
                        child: const Icon(
                          Icons.newspaper_rounded,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Título da matéria/postagem
            Text(
              destaque.titulo,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),

            if (destaque.resumo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  destaque.resumo,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 10.5,
                    height: 1.32,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
