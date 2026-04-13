import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../utils/app_theme.dart';

/// Card de conteúdo expansível com ícone, título e corpo rico.
/// Gerencia o próprio estado de expansão — sem precisar do State pai.
class DetailPremiumCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final String? content;
  final Widget? customContent;

  const DetailPremiumCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accentColor,
    this.content,
    this.customContent,
  });

  @override
  State<DetailPremiumCard> createState() => _DetailPremiumCardState();
}

class _DetailPremiumCardState extends State<DetailPremiumCard> {
  bool _isExpanded = false;

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerRow = Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(widget.icon, color: widget.accentColor, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1A2E)))),
    ]);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? widget.accentColor.withValues(alpha: 0.15) : widget.accentColor.withValues(alpha: 0.2)),
        boxShadow: isDark ? null : [BoxShadow(color: widget.accentColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          widget.content != null
              ? GestureDetector(onTap: _isExpanded ? _toggle : null, behavior: HitTestBehavior.opaque, child: headerRow)
              : headerRow,
          const SizedBox(height: 14),
          if (widget.content != null) _buildRichContent(widget.content!, isDark),
          if (widget.customContent != null) widget.customContent!,
        ]),
      ),
    );

    // Tap card inteiro para expandir quando fechado (só para conteúdo textual)
    if (widget.content != null && !_isExpanded) {
      return GestureDetector(onTap: _toggle, behavior: HitTestBehavior.opaque, child: card);
    }
    return card;
  }

  Widget _buildRichContent(String content, bool isDark) {
    final textColor = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.75);
    final isHtml = RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(content);

    final fullContent = isHtml
        ? HtmlWidget(content, textStyle: TextStyle(fontSize: 15, height: 1.6, color: textColor))
        : Text(content, style: TextStyle(fontSize: 15, height: 1.6, color: textColor));

    if (_isExpanded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        fullContent,
        const SizedBox(height: 8),
        GestureDetector(onTap: _toggle, child: Text('Leia menos ▲', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SumaColors.greenBright))),
      ]);
    }

    if (!isHtml) {
      return LayoutBuilder(builder: (ctx, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: content, style: TextStyle(fontSize: 15, height: 1.6, color: textColor)),
          maxLines: 4, textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(content, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, height: 1.6, color: textColor)),
          if (tp.didExceedMaxLines) ...[
            const SizedBox(height: 8),
            GestureDetector(onTap: _toggle, child: Text('Leia mais... ▼', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SumaColors.greenBright))),
          ],
        ]);
      });
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRect(child: SizedBox(height: 96, child: fullContent)),
      const SizedBox(height: 8),
      GestureDetector(onTap: _toggle, child: Text('Leia mais... ▼', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SumaColors.greenBright))),
    ]);
  }
}
