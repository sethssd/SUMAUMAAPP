import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../models/plant_model.dart';
import '../../../utils/app_theme.dart';
import '../detail_audio_player.dart';
import '../detail_premium_card.dart';
import '../location_review_card.dart';
import '../safety_legend.dart';

/// Aba Geral — "Guia Prático Popular":
/// Tradução direta da ciência para a comunidade: para que serve, como usar com
/// segurança, contraindicações, locais onde encontrar e sabedoria tradicional.
class GeralTab extends StatelessWidget {
  final PlantModel plant;

  const GeralTab({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prioriza a descrição simples, se existir, senão usa a descrição curta ou completa
    final descricaoExibicao = plant.descricaoSimples.trim().isNotEmpty
        ? plant.descricaoSimples
        : (plant.descricaoCurta.trim().isNotEmpty ? plant.descricaoCurta : plant.descricao);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selo de Confiança Científica LABBEX / UFOPA
          _buildInstitutionalBadge(context, isDark),
          const SizedBox(height: 16),

          // 2. "Para que Serve?" (Benefícios Práticos em Destaque)
          if (plant.beneficios.isNotEmpty)
            _buildBeneficiosSection(context, isDark),

          // 3. "Como Usar com Segurança?" (Preparo + Alertas Vermelhos)
          if (plant.comoUsar.isNotEmpty || plant.cuidados.isNotEmpty || (plant.cuidadosAvancados != null && plant.cuidadosAvancados!.isNotEmpty))
            _buildSafetySection(context, plant.comoUsar, plant.cuidados, plant.cuidadosAvancados, isDark),

          // 4. Áudio Popular "Papo de Feira"
          if (plant.audioUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            SumaAudioPlayer(
              audioUrl: plant.audioUrl,
              title: 'Papo de Feira: "O Saber do ${plant.nome}"',
            ),
          ],

          // 5. "O que a Ciência Comprovou?" (Resumo Amigável da Bancada)
          if (plant.descobertasCientificas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildScienceCard(context, plant.descobertasCientificas, isDark),
          ],

          // 6. Conhecendo a Planta (Descrição Amigável e Simples)
          if (descricaoExibicao.isNotEmpty) ...[
            const SizedBox(height: 20),
            DetailPremiumCard(
              icon: Icons.eco_rounded,
              title: 'SOBRE ESTA PLANTA',
              accentColor: SumaColors.greenBright,
              content: descricaoExibicao,
            ),
          ],

          // 7. Onde Encontrar (Feiras, Mercados e Produtores)
          const SizedBox(height: 20),
          if (plant.locais != null && plant.locais!.isNotEmpty)
            LocationReviewCard(locais: plant.locais!)
          else
            _buildLocationSection(context, plant.distribuicaoHabitat, isDark),

          // 8. Card-Convite para Aprofundamento Científico
          const SizedBox(height: 24),
          _buildScientificDeepDivePrompt(context, isDark),
        ],
      ),
    );
  }

  /// Selo de validação científica discreto e de prestígio
  Widget _buildInstitutionalBadge(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E7D32).withValues(alpha: 0.4) : const Color(0xFFA5D6A7),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B5E20) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2E7D32),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesquisa Validada em Bancada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  'Tradução do LABBEX • Universidade Federal do Oeste do Pará (UFOPA)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF2E7D32).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bloco "Para que serve" focado em leitura rápida e pílulas
  Widget _buildBeneficiosSection(BuildContext context, bool isDark) {
    return DetailPremiumCard(
      icon: Icons.favorite_rounded,
      title: 'PARA QUE SERVE?',
      accentColor: const Color(0xFF2E7D32),
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uso popular reconhecido e investigado na região:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          ...plant.beneficios.map((b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildScienceCard(BuildContext context, String content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1810) : const Color(0xFFFFFBEA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.amber.withValues(alpha: 0.15) : Colors.amber.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.biotech_rounded, color: isDark ? Colors.amber.shade300 : Colors.amber.shade800, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'O que o laboratório comprovou?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HtmlWidget(
            content,
            textStyle: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C18) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Onde Encontrar na Região?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text.isNotEmpty ? text : 'Comum em feiras e mercados de Santarém e municípios vizinhos, comercializada por erveiros e produtores locais da nossa região.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection(
    BuildContext context,
    String comoUsar,
    String cuidados,
    List<Map<String, dynamic>>? cuidadosAvancados,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 8),
            Text(
              'Como Usar com Segurança',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (comoUsar.isNotEmpty)
          _safetyBlock(
            isDark,
            const Color(0xFF2E7D32),
            Icons.local_cafe_rounded,
            'Modo de Preparo e Uso',
            comoUsar,
          ),

        if (cuidados.isNotEmpty)
          _safetyBlock(
            isDark,
            const Color(0xFFC62828),
            Icons.warning_amber_rounded,
            'Atenção e Contraindicações',
            cuidados,
          ),

        if (cuidadosAvancados != null && cuidadosAvancados.isNotEmpty) ...[
          const SizedBox(height: 8),
          SafetyLegend(isDark: isDark),
          const SizedBox(height: 12),
          ...cuidadosAvancados.map((c) => CuidadoAvancadoCard(cuidado: c)),
        ],
      ],
    );
  }

  Widget _safetyBlock(bool isDark, Color color, IconData icon, String title, String body) {
    final isAlert = color == const Color(0xFFC62828);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (isAlert ? const Color(0xFF281212) : const Color(0xFF0F2417))
            : (isAlert ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFEF9A9A).withValues(alpha: isDark ? 0.2 : 0.6)
              : const Color(0xFFA5D6A7).withValues(alpha: isDark ? 0.2 : 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                HtmlWidget(
                  body,
                  textStyle: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de fechamento convidando curiosos e acadêmicos a aprofundar
  Widget _buildScientificDeepDivePrompt(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2838) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.indigo, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quer aprofundar na ciência?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Veja fenologia, taxonomia, cromatografia e artigos acadêmicos na aba "Científico" no topo.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
