import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
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
  String? _selectedImageUrl;

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
  //  NOVO HERO HEADER (FASE 1)
  // ══════════════════════════════════════════════════════════════
  Widget _buildNewHeroHeader(Map<String, dynamic> data, bool isDark, BuildContext context) {
    final String nome = data['nome'] ?? 'Nome desconhecido';
    final String nomeCientifico = data['nomeCientifico'] ?? '';

    // Extraindo a imagem principal e outras imagens caso existam
    final String baseImageUrl = data['imagemUrl'] ?? '';
    final List<String> imagensExtras = _parseListField(data['imagensExtras'] ?? data['fotos'] ?? data['imagens']);
    
    // Unindo todas as imagens num set para evitar duplicações
    final List<String> todasImagens = [];
    if (baseImageUrl.isNotEmpty) todasImagens.add(baseImageUrl);
    for (String img in imagensExtras) {
      if (img.isNotEmpty && !todasImagens.contains(img)) {
        todasImagens.add(img);
      }
    }

    // --- MOCK TEMPORÁRIO REMOVIDO ---
    // Agora o painel provê as imagens extras diretamente.

    // Define qual imagem está sendo exibida no fundo
    final String displayUrl = _selectedImageUrl ?? (todasImagens.isNotEmpty ? todasImagens.first : '');

    // Define quais são as "outras imagens" (as que ficarão pequenas na lateral)
    // Ao clicar em uma, ela vira a principal, e a antiga principal desce para essa lista.
    final List<String> imagensLaterais = todasImagens.where((url) => url != displayUrl).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagem Principal
        displayUrl.isNotEmpty
            ? Image.network(displayUrl, fit: BoxFit.cover)
            : Container(color: Colors.green.shade900),

        // Gradiente inferior para mesclar com o fundo
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

        // Botões do Topo (Back, Bookmark, Home)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botão Voltar
              _buildTopControlButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
              // Botões Direita
              Row(
                children: [
                  _buildTopControlButton(Icons.bookmark_border_rounded, () { /* Salvar */ }),
                  const SizedBox(width: 8),
                  _buildTopControlButton(Icons.home_outlined, () => Navigator.popUntil(context, (route) => route.isFirst)),
                ],
              ),
            ],
          ),
        ),

        // Galeria Lateral (Troca com a tela principal)
        if (imagensLaterais.isNotEmpty)
          Positioned(
            right: 30, // Movido mais à esquerda, acima da aba 'Referências'
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: imagensLaterais.take(4).map((url) {
                // Aqui não passamos isSelected porque todas na lateral são não selecionadas
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSelectableThumbnail(url, false), // Falsa pois a principal não tá aqui
                );
              }).toList(),
            ),
          ),

        // Textos Inferiores (Título e Subtítulo)
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                ),
              ),
              if (nomeCientifico.isNotEmpty)
                Text(
                  nomeCientifico,
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildSelectableThumbnail(String url, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _selectedImageUrl = url;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? SumaColors.greenBright : Colors.white.withValues(alpha: 0.2), 
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected) BoxShadow(color: SumaColors.greenBright.withValues(alpha: 0.5), blurRadius: 8),
            const BoxShadow(color: Colors.black45, blurRadius: 5)
          ],
          image: url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PREMIUM TAB BAR (FASE 2)
  // ══════════════════════════════════════════════════════════════
  Widget _buildPremiumTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : SumaColors.greenLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF142F23) : Colors.white,
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
          Tab(text: 'Artigos'),
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
  //  3D MODEL BUTTON (FASE 4)
  // ══════════════════════════════════════════════════════════════
  Widget _build3DButton(String modelo3dUrl, String nome) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    _ModelViewerPage(url: modelo3dUrl, nome: nome),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16593A), // Verde de destaque do modelo 3D
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Modelo 3D',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  AUDIO PLAYER (FASE 8)
  // ══════════════════════════════════════════════════════════════
  Widget _buildAudioPlayer(String nomeDaPlanta, {String? audioUrl}) {
    if (audioUrl == null || audioUrl.trim().isEmpty) {
      return const SizedBox.shrink(); // Planta sem áudio atrelado
    }
    return SumaAudioPlayer(audioUrl: audioUrl, title: 'Papo de Feira: "O Poder do $nomeDaPlanta"');
  }

  // ══════════════════════════════════════════════════════════════
  //  SCIENCE CARD (FASE 3)
  // ══════════════════════════════════════════════════════════════
  Widget _buildScienceCard(String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A14) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.amber.withValues(alpha: 0.05) : Colors.amber.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔎', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'O que a ciência descobriu?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.amber.shade400 : Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SAFETY SECTION (FASE 3)
  // ══════════════════════════════════════════════════════════════
  Widget _buildSafetySection(String comoUsarText, List<String> cuidadosList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.spa_outlined, color: Colors.white70, size: 22),
            const SizedBox(width: 8),
            Text(
              'Como usar com segurança?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (comoUsarText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1C14) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SumaColors.greenBright,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chás e Banhos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SumaColors.greenBright,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comoUsarText,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (cuidadosList.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1212) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuidado com o Óleo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cuidadosList.join('\n'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  LOCATION SECTION (FASE 4)
  // ══════════════════════════════════════════════════════════════
  Widget _buildLocationSection(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Onde Encontrar?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text.isNotEmpty ? text : 'É uma planta muito comum e fácil de achar nas feiras de Santarém, sendo cultivada por produtores locais da nossa região.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFFFF), Color(0xFFCCCCCC)],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
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

    // Novos campos (se existirem) e padronizados com admin
    final String descobertas = data['descobertasCientificas'] ?? data['descricaoSimples'] ?? '';
    final beneficios = _parseListField(data['beneficios']);
    final String comoUsar = data['comoUsar'] ?? '';
    final cuidados = _parseListField(data['cuidados']);
    final nivelEvidencia = data['nivelEvidencia'] ?? 0;
    final numeroEstudos = data['numeroEstudos'] ?? 0;
    final String nome = data['nome'] ?? 'Limãozinho';
    final String audioUrl = data['audioUrl'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio Player Funcional (Fase 8)
          _buildAudioPlayer(nome, audioUrl: audioUrl),

          // "O que a ciência descobriu?" (Fase 3)
          if (descobertas.isNotEmpty)
            _buildScienceCard(descobertas),

          // Descrição principal
          if (descricao.isNotEmpty)
            _buildPremiumCard(
              icon: Icons.article_rounded,
              title: 'DESCRIÇÃO',
              accentColor: SumaColors.greenBright,
              content: descricao,
            ),

          // Seção "Onde Encontrar?" (Fase 4)
          _buildLocationSection(distribuicao),

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

          // Seção de Segurança (Fase 3)
          if (comoUsar.isNotEmpty || cuidados.isNotEmpty)
            _buildSafetySection(comoUsar, cuidados),

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
                // Hero Header Imersivo
                SliverAppBar(
                  expandedHeight: 380,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildNewHeroHeader(data, isDark, context),
                  ),
                ),

                // Conteúdo Principal (Navegação Tabs)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
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
//  COMPONENTE SUMA AUDIO PLAYER (FASE 8)
// ══════════════════════════════════════════════════════════════
class SumaAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;

  const SumaAudioPlayer({super.key, required this.audioUrl, required this.title});

  @override
  State<SumaAudioPlayer> createState() => _SumaAudioPlayerState();
}

class _SumaAudioPlayerState extends State<SumaAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.durationStream.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });

    try {
      _audioPlayer.setUrl(widget.audioUrl);
    } catch (e) {
      debugPrint("Erro ao precarregar áudio: \$e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _seekTo(double value) {
    if (duration != Duration.zero) {
      final newPosition = Duration(milliseconds: value.toInt());
      _audioPlayer.seek(newPosition);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds <= 0) return "00:00";
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : SumaColors.greenLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: () {
              if (isPlaying) {
                setState(() => isPlaying = false); // Resposta imediata na UI
                _audioPlayer.pause();
              } else {
                setState(() => isPlaying = true); // Resposta imediata na UI
                _audioPlayer.play(); // O just_audio usa play nativamente sobre o URL carregado
              }
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: SumaColors.greenBright,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SumaColors.greenBright.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Player Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(_formatDuration(position), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: SumaColors.greenBright,
                          inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                          thumbColor: SumaColors.greenBright,
                        ),
                        child: Slider(
                          min: 0,
                          max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                          value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1).toDouble(),
                          onChanged: _seekTo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatDuration(duration), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  ],
                ),
              ],
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
