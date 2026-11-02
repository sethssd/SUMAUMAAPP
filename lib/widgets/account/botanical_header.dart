import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'sumauma_leaf_data.dart';

/// Cores da área Minha Conta padronizadas com o verde do Hub (SumaColors / SumaGradients).
const Color kAccountGreen = SumaColors.greenAccentDark; // #5E9C52
const Color kAccountGreenLight = SumaColors.greenAccent; // #7AB66E
const Color kAccountGreenDark = Color(0xFF26592C);
const Color kAccountPageBg = SumaColors.lightBg; // #F6F8F6

/// Fundo no mesmo gradiente verde do Hub com a folha da Sumaúma vetorizada (`g2.svg`).
class BotanicalHeaderContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const BotanicalHeaderContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? SumaGradients.darkCard : SumaGradients.searchBar,
        ),
        child: Stack(
          children: [
            // Folha da Sumaúma (g2.svg) à esquerda
            Positioned(
              left: -35,
              bottom: -45,
              width: 220,
              height: 220,
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.26 : 0.34,
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Image.memory(
                      kSumaumaLeafBytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
            // Folha da Sumaúma (g2.svg) central-superior
            Positioned(
              left: 115,
              top: -55,
              width: 205,
              height: 205,
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.22 : 0.28,
                  child: Transform.rotate(
                    angle: 0.78,
                    child: Image.memory(
                      kSumaumaLeafBytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
            // Folha da Sumaúma (g2.svg) principal à direita
            Positioned(
              right: -25,
              top: -30,
              width: 255,
              height: 255,
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.30 : 0.38,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Image.memory(
                      kSumaumaLeafBytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra superior padrão das subtelas da Conta (COLEÇÕES, Favoritos, REFERÊNCIAS, SUGESTÕES).
class BotanicalAppBar extends StatelessWidget {
  final String title;
  final bool uppercaseTitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  const BotanicalAppBar({
    super.key,
    required this.title,
    this.uppercaseTitle = false,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return BotanicalHeaderContainer(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 32,
            ),
            tooltip: 'Voltar',
          ),
          Expanded(
            child: Text(
              uppercaseTitle ? title.toUpperCase() : title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
