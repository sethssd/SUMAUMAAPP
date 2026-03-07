import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final String plantaId;
  const DetailScreen({super.key, required this.plantaId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DocumentSnapshot? _plantaData;
  bool _isLoading = true;

  final Map<String, bool> _expandedTopics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlantaData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlantaData() async {
    try {
      _plantaData = await FirebaseFirestore.instance
          .collection('plantas')
          .doc(widget.plantaId)
          .get();
    } catch (e) {
      debugPrint('Erro ao carregar dados da planta: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleExpansion(String topic) {
    setState(() {
      _expandedTopics[topic] = !(_expandedTopics[topic] ?? false);
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString.trim());
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
        );
      }
    }
  }

  List<String> _parseListField(dynamic data) {
    if (data is List) return data.map((item) => item.toString()).toList();
    if (data is String) return data.split(',').map((e) => e.trim()).toList();
    return [];
  }

  String _getEvidenceLevelText(int nivel) {
    switch (nivel) {
      case 5:
        return "Evidência Muito Alta";
      case 4:
        return "Evidência Alta";
      case 3:
        return "Evidência Moderada";
      case 2:
        return "Evidência Baixa";
      case 1:
        return "Uso Tradicional";
      default:
        return "Sem Classificação";
    }
  }

  String _formatChemicalName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _copyReference(Map<String, dynamic> ref) {
    final citation =
        "${ref['autores'] ?? 'Autores desconhecidos'}. ${ref['titulo'] ?? 'Sem título'}. ${ref['ano'] ?? ''}.";
    Clipboard.setData(ClipboardData(text: citation));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Referência copiada para a área de transferência"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  HERO IMAGE CARD — imagem arredondada no topo
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeroImageCard(Map<String, dynamic> data) {
    final String imagemUrl = data['imagemUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: imagemUrl.isNotEmpty
            ? Image.network(
                imagemUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.eco_rounded,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  INFO HEADER — Nome, nome científico, descrição curta
  // ══════════════════════════════════════════════════════════════
  Widget _buildInfoHeader(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String nome = data['nome'] ?? 'Nome desconhecido';
    final String nomeCientifico = data['nomeCientifico'] ?? '';
    final String descricaoCurta =
        data['descricaoCurta'] ?? data['descricao'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nome,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              letterSpacing: -0.5,
            ),
          ),
          if (nomeCientifico.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              nomeCientifico,
              style: TextStyle(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: SumaColors.greenBright,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (descricaoCurta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              descricaoCurta,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PREMIUM TAB BAR
  // ══════════════════════════════════════════════════════════════
  Widget _buildPremiumTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : SumaColors.greenLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? SumaColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: SumaColors.greenBright,
        unselectedLabelColor: isDark
            ? Colors.white.withValues(alpha: 0.5)
            : SumaColors.greenMid.withValues(alpha: 0.6),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Geral'),
          Tab(text: 'Científico'),
          Tab(text: 'Referências'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PREMIUM CARD WRAPPER
  // ══════════════════════════════════════════════════════════════
  Widget _buildPremiumCard({
    required IconData icon,
    required String title,
    required Color accentColor,
    String? content,
    Widget? customContent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isExpanded = _expandedTopics[title] ?? false;

    // Header row (icon + title)
    Widget headerRow = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );

    // When expanded, make header tappable to collapse
    if (isExpanded && content != null) {
      headerRow = GestureDetector(
        onTap: () => _toggleExpansion(title),
        behavior: HitTestBehavior.opaque,
        child: headerRow,
      );
    }

    Widget cardBody = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? accentColor.withValues(alpha: 0.15)
              : accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerRow,
            const SizedBox(height: 14),
            if (content != null) _buildRichContent(content, expandKey: title),
            if (customContent != null) customContent,
          ],
        ),
      ),
    );

    // When collapsed, make entire card tappable to expand
    if (!isExpanded && content != null) {
      return GestureDetector(
        onTap: () => _toggleExpansion(title),
        behavior: HitTestBehavior.opaque,
        child: cardBody,
      );
    }

    return cardBody;
  }

  // ══════════════════════════════════════════════════════════════
  //  RICH CONTENT RENDERER with "Leia mais / Leia menos"
  // ══════════════════════════════════════════════════════════════
  Widget _buildRichContent(String content, {String expandKey = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.75);
    final bool isExpanded = _expandedTopics[expandKey] ?? false;

    // Detect if content contains HTML tags
    final bool isHtml = RegExp(
      r'<[a-z][\s\S]*>',
      caseSensitive: false,
    ).hasMatch(content);

    final Widget fullContent = isHtml
        ? HtmlWidget(
            content,
            textStyle: TextStyle(fontSize: 15, height: 1.6, color: textColor),
          )
        : Text(
            content,
            style: TextStyle(fontSize: 15, height: 1.6, color: textColor),
          );

    // If expanded, show full content + "Leia menos"
    if (isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fullContent,
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _toggleExpansion(expandKey),
            child: Text(
              'Leia menos ▲',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SumaColors.greenBright,
              ),
            ),
          ),
        ],
      );
    }

    // Collapsed: use LayoutBuilder to detect overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        // For plain text, we can measure lines directly
        if (!isHtml) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: content,
              style: TextStyle(fontSize: 15, height: 1.6, color: textColor),
            ),
            maxLines: 4,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          final bool overflows = textPainter.didExceedMaxLines;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, height: 1.6, color: textColor),
              ),
              if (overflows) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _toggleExpansion(expandKey),
                  child: Text(
                    'Leia mais... ▼',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SumaColors.greenBright,
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        // For HTML content: show clipped container with gradient fade
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRect(
              child: SizedBox(
                height: 96, // ~4 lines at 15px * 1.6 line-height
                child: fullContent,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _toggleExpansion(expandKey),
              child: Text(
                'Leia mais... ▼',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SumaColors.greenBright,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  3D MODEL BUTTON
  // ══════════════════════════════════════════════════════════════
  Widget _build3DButton(String modelo3dUrl, String nome) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    _ModelViewerPage(url: modelo3dUrl, nome: nome),
              ),
            );
          },
          icon: const Icon(Icons.view_in_ar_rounded, size: 22),
          label: const Text(
            'Ver Modelo 3D',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: SumaColors.greenBright,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: SumaColors.greenBright.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ABA GERAL
  // ══════════════════════════════════════════════════════════════
  Widget _buildGeralTab(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String descricao = data['descricao'] ?? '';
    final String distribuicao = data['distribuicaoHabitat'] ?? '';
    final String fenologia = data['fenologia'] ?? '';
    final String usosValor = data['usosEValorEconomico'] ?? '';
    final String taxonomia = data['taxonomiaNomesPopulares'] ?? '';

    // Novos campos (se existirem)
    final String descricaoSimples = data['descricaoSimples'] ?? '';
    final beneficios = _parseListField(data['beneficios']);
    final String comoUsar = data['comoUsar'] ?? '';
    final cuidados = _parseListField(data['cuidados']);
    final nivelEvidencia = data['nivelEvidencia'] ?? 0;
    final numeroEstudos = data['numeroEstudos'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "O que é?" — se houver descrição simples
          if (descricaoSimples.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'O QUE É?',
              accentColor: Colors.blue,
              content: descricaoSimples,
            ),

          // Descrição principal
          if (descricao.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.article_rounded,
              title: 'DESCRIÇÃO',
              accentColor: SumaColors.greenBright,
              content: descricao,
            ),

          // Distribuição e Habitat
          if (distribuicao.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.map_rounded,
              title: 'DISTRIBUIÇÃO E HABITAT',
              accentColor: const Color(0xFF2D6A4F),
              content: distribuicao,
            ),

          // Taxonomia / Nomes Populares
          if (taxonomia.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.category_rounded,
              title: 'TAXONOMIA / NOMES POPULARES',
              accentColor: Colors.purple,
              content: taxonomia,
            ),

          // Fenologia
          if (fenologia.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.calendar_month_rounded,
              title: 'FENOLOGIA',
              accentColor: Colors.orange,
              content: fenologia,
            ),

          // Usos e Valor Econômico
          if (usosValor.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.storefront_rounded,
              title: 'USOS E VALOR ECONÔMICO',
              accentColor: Colors.teal,
              content: usosValor,
            ),

          // Benefícios
          if (beneficios.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.medical_services_outlined,
              title: 'PARA QUE SERVE?',
              accentColor: Colors.green,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: beneficios
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : const Color(
                                          0xFF1A1A2E,
                                        ).withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Como usar
          if (comoUsar.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.restaurant_outlined,
              title: 'COMO USAR?',
              accentColor: Colors.orange,
              content: comoUsar,
            ),

          // Cuidados
          if (cuidados.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.warning_amber_rounded,
              title: 'CUIDADOS',
              accentColor: Colors.red,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cuidados
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : const Color(
                                          0xFF1A1A2E,
                                        ).withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Nível de Evidência
          if (nivelEvidencia > 0)
            _buildPremiumCard(
              icon: Icons.bar_chart_rounded,
              title: 'NÍVEL DE EVIDÊNCIA CIENTÍFICA',
              accentColor: Colors.amber,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < nivelEvidencia
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 28,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEvidenceLevelText(nivelEvidencia),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  if (numeroEstudos > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Baseado em $numeroEstudos estudos científicos',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ABA CIENTÍFICA
  // ══════════════════════════════════════════════════════════════
  Widget _buildCientificoTab(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String farmacologia = data['farmacologia'] ?? '';
    final composicao = data['composicaoQuimica'] as Map<String, dynamic>?;
    final propriedades = data['propriedadesFarmacologicas'] as List<dynamic>?;
    final tiposEstudo = data['tiposEstudo'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Composição Química
          if (composicao != null && composicao.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.science_rounded,
              title: 'COMPOSIÇÃO QUÍMICA',
              accentColor: Colors.purple,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: composicao.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : const Color(
                                        0xFF1A1A2E,
                                      ).withValues(alpha: 0.75),
                              ),
                              children: [
                                TextSpan(
                                  text: '${_formatChemicalName(entry.key)}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: entry.value.toString()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Propriedades Farmacológicas
          if (propriedades != null && propriedades.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.biotech_rounded,
              title: 'PROPRIEDADES FARMACOLÓGICAS',
              accentColor: Colors.teal,
              customContent: Column(
                children: propriedades.map((prop) {
                  return _buildExpandableProperty(prop as Map<String, dynamic>);
                }).toList(),
              ),
            ),

          // Estudos Clínicos
          if (tiposEstudo != null && tiposEstudo.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.analytics_rounded,
              title: 'ESTUDOS CLÍNICOS',
              accentColor: Colors.indigo,
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tiposEstudo.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.indigo,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatChemicalName(entry.key)}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : const Color(
                                      0xFF1A1A2E,
                                    ).withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Farmacologia (texto legado)
          if (farmacologia.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.description_rounded,
              title: 'FARMACOLOGIA',
              accentColor: SumaColors.greenBright,
              content: farmacologia,
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableProperty(Map<String, dynamic> property) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipo = property['tipo'] ?? 'Propriedade';
    final isExpanded = _expandedTopics[tipo] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpansion(tipo),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (property['ic50'] != null)
                  Text(
                    'IC50: ${property['ic50']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                if (property['mecanismo'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Mecanismo: ${property['mecanismo']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                if (property['detalhes'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      property['detalhes'],
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Divider(
          height: 1,
          color: isDark ? SumaColors.darkDivider : const Color(0xFFE0EDE4),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ABA REFERÊNCIAS
  // ══════════════════════════════════════════════════════════════
  Widget _buildReferenciasTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralReferencesSection(data),
          const SizedBox(height: 16),
          _buildScientificReferencesSection(data),
        ],
      ),
    );
  }

  Widget _buildGeneralReferencesSection(Map<String, dynamic> data) {
    final refGeral = _parseListField(data['referenciaGeral']);
    final validLinks = refGeral
        .where((link) => link.trim().isNotEmpty)
        .toList();

    if (validLinks.isEmpty) return const SizedBox.shrink();

    return _buildPremiumCard(
      icon: Icons.menu_book_rounded,
      title: 'REFERÊNCIAS GERAIS (${validLinks.length})',
      accentColor: SumaColors.greenBright,
      customContent: Column(
        children: validLinks.map((link) {
          return _buildReferenceLink(link, SumaColors.greenBright);
        }).toList(),
      ),
    );
  }

  Widget _buildScientificReferencesSection(Map<String, dynamic> data) {
    final referenciasCientificas =
        data['referenciasCientificas'] as List<dynamic>?;

    if (referenciasCientificas != null && referenciasCientificas.isNotEmpty) {
      return _buildPremiumCard(
        icon: Icons.science_rounded,
        title: 'REFERÊNCIAS CIENTÍFICAS (${referenciasCientificas.length})',
        accentColor: Colors.blue,
        customContent: Column(
          children: referenciasCientificas.map((ref) {
            return _buildScientificReferenceItem(ref as Map<String, dynamic>);
          }).toList(),
        ),
      );
    }

    // Fallback para referências farmacológicas antigas
    final refFarmacologicas = _parseListField(
      data['referenciasFarmacologicas'],
    );
    final validLinks = refFarmacologicas
        .where((link) => link.trim().isNotEmpty)
        .toList();

    if (validLinks.isEmpty) return const SizedBox.shrink();

    return _buildPremiumCard(
      icon: Icons.science_rounded,
      title: 'REFERÊNCIAS CIENTÍFICAS (${validLinks.length})',
      accentColor: Colors.blue,
      customContent: Column(
        children: validLinks.map((link) {
          return _buildReferenceLink(link, Colors.blue);
        }).toList(),
      ),
    );
  }

  Widget _buildReferenceLink(String link, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _launchURL(link),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  link.length > 55 ? '${link.substring(0, 55)}…' : link,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScientificReferenceItem(Map<String, dynamic> ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withValues(alpha: 0.06)
            : Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref['titulo'] ?? 'Sem título',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${ref['autores'] ?? 'Autores desconhecidos'} • ${ref['ano'] ?? ''}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          if (ref['pmid'] != null || ref['doi'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                ref['pmid'] != null
                    ? 'PMID: ${ref['pmid']}'
                    : 'DOI: ${ref['doi']}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade400,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          if (ref['citacoes'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ref['citacoes']} citações',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (ref['url'] != null)
                _buildMiniButton(
                  Icons.open_in_new_rounded,
                  'Abrir',
                  () => _launchURL(ref['url'] ?? ''),
                ),
              const SizedBox(width: 8),
              _buildMiniButton(
                Icons.content_copy_rounded,
                'Citar',
                () => _copyReference(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SumaColors.greenBright.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: SumaColors.greenBright),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SumaColors.greenBright,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_plantaData == null || !_plantaData!.exists) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Planta não encontrada.')),
      );
    }

    final data = _plantaData!.data() as Map<String, dynamic>;
    final String nome = data['nome'] ?? 'Nome Desconhecido';
    final String modelo3dUrl = data['modelo3dUrl'] ?? '';
    final bool hasModel3D = modelo3dUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : const Color(0xFFF6FBF7),
      body: Column(
        children: [
          // ── TOP SECTION (scrollável) ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // AppBar transparente
                SliverAppBar(
                  expandedHeight: 0,
                  pinned: true,
                  backgroundColor: isDark
                      ? SumaColors.darkBg
                      : const Color(0xFFF6FBF7),
                  foregroundColor: isDark ? Colors.white : SumaColors.greenDeep,
                  iconTheme: IconThemeData(
                    color: isDark ? Colors.white : SumaColors.greenDeep,
                  ),
                  elevation: 0,
                  title: Text(
                    nome,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : SumaColors.greenDeep,
                    ),
                  ),
                  centerTitle: true,
                ),

                // Conteúdo Principal
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Imagem arredondada (Hero Card)
                      _buildHeroImageCard(data),
                      // Info: Nome, nome científico, descrição
                      _buildInfoHeader(data),
                      // Tab Bar Premium
                      _buildPremiumTabBar(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeralTab(data),
                      _buildCientificoTab(data),
                      _buildReferenciasTab(data),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BOTÃO 3D (fixo embaixo) ──
          if (hasModel3D)
            SafeArea(
              top: false,
              child: Container(
                color: isDark ? SumaColors.darkBg : const Color(0xFFF6FBF7),
                child: _build3DButton(modelo3dUrl, nome),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TELA DE VISUALIZAÇÃO 3D
// ══════════════════════════════════════════════════════════════
class _ModelViewerPage extends StatelessWidget {
  final String url;
  final String nome;

  const _ModelViewerPage({required this.url, required this.nome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: ModelViewer(
        src: url,
        ar: true,
        alt: nome,
        cameraControls: true,
        autoRotate: true,
      ),
    );
  }
}
