import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../utils/app_theme.dart';

/// Header imersivo com foto principal + galeria lateral de miniaturas.
/// Gerencia o estado de seleção de imagem localmente para não poluir o pai.
class DetailHeroHeader extends StatefulWidget {
  final PlantModel plant;

  const DetailHeroHeader({super.key, required this.plant});

  @override
  State<DetailHeroHeader> createState() => _DetailHeroHeaderState();
}

class _DetailHeroHeaderState extends State<DetailHeroHeader> {
  String? _selectedImageUrl;

  List<String> get _allImages {
    final all = <String>[];
    if (widget.plant.imagemUrl.isNotEmpty) all.add(widget.plant.imagemUrl);
    for (final img in widget.plant.imagensExtras) {
      if (img.isNotEmpty && !all.contains(img)) all.add(img);
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todasImagens = _allImages;
    final displayUrl = _selectedImageUrl ?? (todasImagens.isNotEmpty ? todasImagens.first : '');
    final imagensLaterais = todasImagens.where((url) => url != displayUrl).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagem Principal
        displayUrl.isNotEmpty
            ? Image.network(displayUrl, fit: BoxFit.cover)
            : Container(color: Colors.green.shade900),

        // Gradiente inferior
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.5),
                  isDark ? SumaColors.darkBg : const Color(0xFFF6FBF7),
                ],
                stops: const [0.3, 0.6, 0.85, 1.0],
              ),
            ),
          ),
        ),

        // Botões do Topo
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
              Row(children: [
                _buildTopBtn(Icons.bookmark_border_rounded, () {}),
                const SizedBox(width: 8),
                _buildTopBtn(Icons.home_outlined, () => Navigator.popUntil(context, (r) => r.isFirst)),
              ]),
            ],
          ),
        ),

        // Galeria Lateral
        if (imagensLaterais.isNotEmpty)
          Positioned(
            right: 30,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: imagensLaterais.take(4).map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildThumbnail(url),
              )).toList(),
            ),
          ),

        // Títulos
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.plant.nome,
                style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                ),
              ),
              if (widget.plant.nomeCientifico.isNotEmpty)
                Text(
                  widget.plant.nomeCientifico,
                  style: const TextStyle(
                    fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildThumbnail(String url) {
    return GestureDetector(
      onTap: () => setState(() => _selectedImageUrl = url),
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
          image: url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        ),
      ),
    );
  }
}
