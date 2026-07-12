import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/destaque_model.dart';
import '../../utils/app_theme.dart';

/// Carrossel de banners "Destaques" com auto-scroll e indicador de página.
class DestaqueCarousel extends StatefulWidget {
  final List<DestaqueModel> destaques;

  const DestaqueCarousel({super.key, required this.destaques});

  @override
  State<DestaqueCarousel> createState() => _DestaqueCarouselState();
}

class _DestaqueCarouselState extends State<DestaqueCarousel> {
  int _current = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destaques.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Título da seção ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: SumaColors.greenBright,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DESTAQUES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white70 : SumaColors.greenDeep,
                ),
              ),
              const Spacer(),
              // Indicadores de página
              Row(
                children: List.generate(widget.destaques.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 4),
                    width: _current == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? SumaColors.greenBright
                          : (isDark ? Colors.white24 : const Color(0xFFB7DFC6)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        // ── Carrossel ─────────────────────────────────────────
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.destaques.length,
          options: CarouselOptions(
            height: 180,
            viewportFraction: 0.92,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final d = widget.destaques[index];
            return GestureDetector(
              onTap: () => _openLink(d.link),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isDark ? SumaColors.darkCard : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagem de fundo
                    if (d.imagemUrl.isNotEmpty)
                      Image.network(
                        d.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SumaColors.greenDeep.withValues(alpha: 0.8),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [SumaColors.greenDeep, SumaColors.greenMid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                    // Gradiente de leitura
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.35, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Textos
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                            ),
                          ),
                          if (d.resumo.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              d.resumo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Badge "Leia mais" se tiver link
                    if (d.link.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SumaColors.greenBright.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Leia mais',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
