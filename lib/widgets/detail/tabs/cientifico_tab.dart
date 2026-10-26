import 'package:flutter/material.dart';
import '../../../models/plant_model.dart';
import '../detail_premium_card.dart';

/// Aba Científica: composição química, propriedades farmacológicas, estudos clínicos.
class CientificoTab extends StatefulWidget {
  final PlantModel plant;

  const CientificoTab({super.key, required this.plant});

  @override
  State<CientificoTab> createState() => _CientificoTabState();
}

class _CientificoTabState extends State<CientificoTab> {
  final Map<String, bool> _expanded = {};

  void _toggle(String key) => setState(() => _expanded[key] = !(_expanded[key] ?? false));

  String _formatKey(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').trim()
        .split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plant = widget.plant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.taxonomiaNomesPopulares.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.account_tree_rounded,
              title: 'TAXONOMIA BOTÂNICA',
              accentColor: Colors.deepPurple,
              content: plant.taxonomiaNomesPopulares,
            ),

          if (plant.fenologia.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.calendar_month_rounded,
              title: 'FENOLOGIA (CICLO REPRODUTIVO)',
              accentColor: Colors.orange,
              content: plant.fenologia,
            ),

          if (plant.usosEValorEconomico.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.agriculture_rounded,
              title: 'USOS E VALOR ECONÔMICO',
              accentColor: Colors.brown,
              content: plant.usosEValorEconomico,
            ),

          if (plant.composicaoQuimica != null && plant.composicaoQuimica!.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.science_rounded,
              title: 'COMPOSIÇÃO QUÍMICA',
              accentColor: Colors.purple,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plant.composicaoQuimica!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('• ', style: const TextStyle(fontSize: 16, color: Colors.purple, fontWeight: FontWeight.bold)),
                    Expanded(child: RichText(text: TextSpan(
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF1A1A2E).withValues(alpha: 0.75)),
                      children: [
                        TextSpan(text: '${_formatKey(entry.key)}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: entry.value.toString()),
                      ],
                    ))),
                  ]),
                )).toList(),
              ),
            ),

          if (plant.propriedadesFarmacologicas != null && plant.propriedadesFarmacologicas!.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.biotech_rounded,
              title: 'PROPRIEDADES FARMACOLÓGICAS',
              accentColor: Colors.teal,
              customContent: Column(
                children: plant.propriedadesFarmacologicas!.map((prop) =>
                    _expandableProperty(prop as Map<String, dynamic>, isDark)).toList(),
              ),
            ),

          if (plant.tiposEstudo != null && plant.tiposEstudo!.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.analytics_rounded,
              title: 'ESTUDOS CLÍNICOS',
              accentColor: Colors.indigo,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plant.tiposEstudo!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.indigo, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${_formatKey(entry.key)}: ${entry.value}', style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF1A1A2E).withValues(alpha: 0.75)))),
                  ]),
                )).toList(),
              ),
            ),

          if (plant.farmacologia.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.description_rounded,
              title: 'FARMACOLOGIA',
              accentColor: Colors.green,
              content: plant.farmacologia,
            ),
        ],
      ),
    );
  }

  Widget _expandableProperty(Map<String, dynamic> property, bool isDark) {
    final tipo = property['tipo'] ?? 'Propriedade';
    final isExpanded = _expanded[tipo] ?? false;
    return Column(children: [
      InkWell(
        onTap: () => _toggle(tipo),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(tipo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1A1A2E)))),
          ]),
        ),
      ),
      if (isExpanded)
        Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (property['ic50'] != null) Text('IC50: ${property['ic50']}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700)),
            if (property['mecanismo'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Mecanismo: ${property['mecanismo']}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700))),
            if (property['detalhes'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(property['detalhes'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700))),
          ]),
        ),
      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE0EDE4)),
    ]);
  }
}
