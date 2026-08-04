import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/plant_model.dart';
import '../../../utils/app_theme.dart';
import '../detail_audio_player.dart';
import '../detail_premium_card.dart';
import '../location_review_card.dart';
import '../safety_legend.dart';

/// Aba Geral: descrição, taxonomia, fenologia, usos, localização, benefícios, segurança e áudio.
class GeralTab extends StatelessWidget {
  final PlantModel plant;

  const GeralTab({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.audioUrl.isNotEmpty)
            SumaAudioPlayer(
              audioUrl: plant.audioUrl,
              title: 'Papo de Feira: "O Poder do ${plant.nome}"',
            ),

          if (plant.descobertasCientificas.isNotEmpty)
            _buildScienceCard(context, plant.descobertasCientificas, isDark),

          if (plant.descricao.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.article_rounded,
              title: 'DESCRIÇÃO',
              accentColor: SumaColors.greenBright,
              content: plant.descricao,
            ),

          if (plant.taxonomiaNomesPopulares.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.category_rounded,
              title: 'TAXONOMIA / NOMES POPULARES',
              accentColor: Colors.purple,
              content: plant.taxonomiaNomesPopulares,
            ),

          if (plant.fenologia.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.calendar_month_rounded,
              title: 'FENOLOGIA',
              accentColor: Colors.orange,
              content: plant.fenologia,
            ),

          if (plant.usosEValorEconomico.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.storefront_rounded,
              title: 'USOS E VALOR ECONÔMICO',
              accentColor: Colors.teal,
              content: plant.usosEValorEconomico,
            ),

          if (plant.locais != null && plant.locais!.isNotEmpty)
            LocationReviewCard(locais: plant.locais!)
          else
            _buildLocationSection(context, plant.distribuicaoHabitat, isDark),

          if (plant.beneficios.isNotEmpty)
            DetailPremiumCard(
              icon: Icons.medical_services_outlined,
              title: 'PARA QUE SERVE?',
              accentColor: Colors.green,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plant.beneficios.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b, style: TextStyle(fontSize: 15, color: isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF1A1A2E).withValues(alpha: 0.75)))),
                    ],
                  ),
                )).toList(),
              ),
            ),

          if (plant.comoUsar.isNotEmpty || plant.cuidados.isNotEmpty || (plant.cuidadosAvancados != null && plant.cuidadosAvancados!.isNotEmpty))
            _buildSafetySection(context, plant.comoUsar, plant.cuidados, plant.cuidadosAvancados, isDark),
        ],
      ),
    );
  }

  Widget _buildScienceCard(BuildContext context, String content, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A14) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.amber.withValues(alpha: 0.05) : Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SvgPicture.asset('assets/icons/navegacao/microscopio.svg', width: 22, colorFilter: ColorFilter.mode(isDark ? Colors.amber.shade400 : Colors.amber.shade700, BlendMode.srcIn)),
          const SizedBox(width: 8),
          Expanded(child: Text('O que a ciência descobriu?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.amber.shade400 : Colors.amber.shade700))),
        ]),
        const SizedBox(height: 12),
        HtmlWidget(content, textStyle: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade800)),
      ]),
    );
  }

  Widget _buildLocationSection(BuildContext context, String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.location_on_outlined, color: isDark ? Colors.white : const Color(0xFF1A1A2E), size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text('Onde Encontrar?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
        ]),
        const SizedBox(height: 12),
        Text(
          text.isNotEmpty ? text : 'É uma planta muito comum e fácil de achar nas feiras de Santarém, sendo cultivada por produtores locais da nossa região.',
          style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.grey.shade700),
        ),
      ]),
    );
  }

  Widget _buildSafetySection(BuildContext context, String comoUsar, String cuidados, List<Map<String, dynamic>>? cuidadosAvancados, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SvgPicture.asset('assets/icons/medicinais/imunidade.svg', width: 22, colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
        const SizedBox(width: 8),
        Text('Como usar com segurança?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
      ]),
      const SizedBox(height: 16),
      
      if (cuidadosAvancados != null && cuidadosAvancados.isNotEmpty) ...[
        SafetyLegend(isDark: isDark),
        const SizedBox(height: 16),
        ...cuidadosAvancados.map((c) => CuidadoAvancadoCard(cuidado: c)),
      ],

      if (comoUsar.isNotEmpty)
        _safetyBlock(isDark, SumaColors.greenBright, 'assets/icons/ficha/folha.svg', 'Chás e Banhos', comoUsar),
      if (cuidados.isNotEmpty)
        _safetyBlock(isDark, const Color(0xFFD32F2F), 'assets/icons/alertas/toxidade_alta.svg', 'Cuidado com o Óleo', cuidados),
    ]);
  }

  Widget _safetyBlock(bool isDark, Color color, String iconPath, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? (color == SumaColors.greenBright ? const Color(0xFF0F1C14) : const Color(0xFF1A1212)) : (color == SumaColors.greenBright ? Colors.green.shade50 : Colors.red.shade50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Center(child: SvgPicture.asset(iconPath, width: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          HtmlWidget(body, textStyle: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : Colors.grey.shade700)),
        ])),
      ]),
    );
  }
}
