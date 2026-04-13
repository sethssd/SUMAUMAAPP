import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/plant_model.dart';
import '../../../utils/app_theme.dart';
import '../detail_premium_card.dart';

/// Aba Referências: links gerais e artigos científicos citáveis.
class ReferenciasTab extends StatelessWidget {
  final PlantModel plant;

  const ReferenciasTab({super.key, required this.plant});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
        );
      }
    }
  }

  void _copyReference(BuildContext context, Map<String, dynamic> ref) {
    final citation = '${ref['autores'] ?? 'Autores desconhecidos'}. ${ref['titulo'] ?? 'Sem título'}. ${ref['ano'] ?? ''}.';
    Clipboard.setData(ClipboardData(text: citation));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referência copiada para a área de transferência'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildGeneralRefs(context),
        const SizedBox(height: 16),
        _buildScientificRefs(context),
      ]),
    );
  }

  Widget _buildGeneralRefs(BuildContext context) {
    final valid = plant.referenciaGeral.where((l) => l.trim().isNotEmpty).toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    return DetailPremiumCard(
      icon: Icons.menu_book_rounded,
      title: 'REFERÊNCIAS GERAIS (${valid.length})',
      accentColor: SumaColors.greenBright,
      customContent: Column(children: valid.map((l) => _linkItem(context, l, SumaColors.greenBright)).toList()),
    );
  }

  Widget _buildScientificRefs(BuildContext context) {
    if (plant.referenciasCientificas != null && plant.referenciasCientificas!.isNotEmpty) {
      return DetailPremiumCard(
        icon: Icons.science_rounded,
        title: 'REFERÊNCIAS CIENTÍFICAS (${plant.referenciasCientificas!.length})',
        accentColor: Colors.blue,
        customContent: Column(children: plant.referenciasCientificas!.map((ref) => _sciRef(context, ref as Map<String, dynamic>)).toList()),
      );
    }
    final valid = plant.referenciasFarmacologicas.where((l) => l.trim().isNotEmpty).toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    return DetailPremiumCard(
      icon: Icons.science_rounded,
      title: 'REFERÊNCIAS CIENTÍFICAS (${valid.length})',
      accentColor: Colors.blue,
      customContent: Column(children: valid.map((l) => _linkItem(context, l, Colors.blue)).toList()),
    );
  }

  Widget _linkItem(BuildContext context, String link, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _launchURL(context, link),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Icons.link_rounded, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(link.length > 55 ? '${link.substring(0, 55)}…' : link, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500))),
            Icon(Icons.open_in_new_rounded, color: color, size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _sciRef(BuildContext context, Map<String, dynamic> ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withValues(alpha: 0.06) : Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ref['titulo'] ?? 'Sem título', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        Text('${ref['autores'] ?? 'Autores desconhecidos'} • ${ref['ano'] ?? ''}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
        if (ref['pmid'] != null || ref['doi'] != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(ref['pmid'] != null ? 'PMID: ${ref['pmid']}' : 'DOI: ${ref['doi']}', style: TextStyle(fontSize: 11, color: Colors.blue.shade400, fontFamily: 'monospace'))),
        if (ref['citacoes'] != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
            Icon(Icons.format_quote_rounded, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text('${ref['citacoes']} citações', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
        const SizedBox(height: 8),
        Row(children: [
          if (ref['url'] != null) _miniBtn(context, Icons.open_in_new_rounded, 'Abrir', () => _launchURL(context, ref['url'] ?? '')),
          const SizedBox(width: 8),
          _miniBtn(context, Icons.content_copy_rounded, 'Citar', () => _copyReference(context, ref)),
        ]),
      ]),
    );
  }

  Widget _miniBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: SumaColors.greenBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: SumaColors.greenBright),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SumaColors.greenBright)),
        ]),
      ),
    );
  }
}
