import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
      debugPrint('Não foi possível abrir o link: $urlString');
    }
  }

  List<String> _parseListField(dynamic data) {
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    if (data is String) {
      return data.split(',').map((e) => e.trim()).toList();
    }
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

  // ==================== HEADER ====================
  Widget _buildPlantHeader(Map<String, dynamic> data) {
    final String imagemUrl = data['imagemUrl'] ?? '';
    final String modelo3dUrl = data['modelo3dUrl'] ?? '';
    final String nome = data['nome'] ?? 'Nome Desconhecido';
    final bool hasModel3D = modelo3dUrl.isNotEmpty;

    if (hasModel3D) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: ModelViewer(
          src: modelo3dUrl,
          ar: false,
          alt: nome,
          cameraControls: true,
          autoRotate: true,
        ),
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imagemUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(179)],
              ),
            ),
          ),
        ],
      );
    }
  }

  // ==================== ABA GERAL ====================
  Widget _buildGeralTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWhatIsCard(data),
          const SizedBox(height: 16),
          _buildBenefitsCard(data),
          const SizedBox(height: 16),
          _buildUsageCard(data),
          const SizedBox(height: 16),
          _buildWarningsCard(data),
          const SizedBox(height: 16),
          _buildEvidenceCard(data),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildWhatIsCard(Map<String, dynamic> data) {
    final String descricaoSimples =
        data['descricaoSimples'] ??
        data['descricaoCurta'] ??
        data['descricao'] ??
        'Descrição não disponível';

    return _buildSectionCard(
      icon: Icons.lightbulb_outline,
      title: "O QUE É?",
      content: descricaoSimples,
      color: Colors.blue[50]!,
    );
  }

  Widget _buildBenefitsCard(Map<String, dynamic> data) {
    final beneficios = _parseListField(data['beneficios']);

    if (beneficios.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      icon: Icons.medical_services_outlined,
      title: "PARA QUE SERVE?",
      color: Colors.green[50]!,
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: beneficios.map((beneficio) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(beneficio, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsageCard(Map<String, dynamic> data) {
    final String comoUsar = data['comoUsar'] ?? '';

    if (comoUsar.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      icon: Icons.restaurant_outlined,
      title: "COMO USAR?",
      content: comoUsar,
      color: Colors.orange[50]!,
    );
  }

  Widget _buildWarningsCard(Map<String, dynamic> data) {
    final cuidados = _parseListField(data['cuidados']);

    if (cuidados.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      icon: Icons.warning_amber_outlined,
      title: "CUIDADOS",
      color: Colors.red[50]!,
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cuidados.map((cuidado) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cuidado, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> data) {
    final nivelEvidencia = data['nivelEvidencia'] ?? 3;
    final numeroEstudos = data['numeroEstudos'] ?? 0;

    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "NÍVEL DE EVIDÊNCIA CIENTÍFICA",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < nivelEvidencia ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                  size: 32,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getEvidenceLevelText(nivelEvidencia),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber[900],
              ),
            ),
            if (numeroEstudos > 0) ...[
              const SizedBox(height: 4),
              Text(
                "Baseado em $numeroEstudos estudos científicos",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== ABA CIENTÍFICA ====================
  Widget _buildCientificoTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChemicalCompositionCard(data),
          const SizedBox(height: 16),
          _buildPharmacologicalPropertiesCard(data),
          const SizedBox(height: 16),
          _buildClinicalStudiesCard(data),
          const SizedBox(height: 16),
          _buildLegacyScientificContent(data),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildChemicalCompositionCard(Map<String, dynamic> data) {
    final composicao = data['composicaoQuimica'] as Map<String, dynamic>?;

    if (composicao == null || composicao.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "COMPOSIÇÃO QUÍMICA",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...composicao.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: "${_formatChemicalName(entry.key)}: ",
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacologicalPropertiesCard(Map<String, dynamic> data) {
    final propriedades = data['propriedadesFarmacologicas'] as List<dynamic>?;

    if (propriedades == null || propriedades.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.biotech, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "PROPRIEDADES FARMACOLÓGICAS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...propriedades.map((prop) {
              return _buildExpandableProperty(prop as Map<String, dynamic>);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableProperty(Map<String, dynamic> property) {
    final tipo = property['tipo'] ?? 'Propriedade';
    final isExpanded = _expandedTopics[tipo] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpansion(tipo),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.teal[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (property['ic50'] != null)
                  Text(
                    "IC50: ${property['ic50']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                if (property['mecanismo'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Mecanismo: ${property['mecanismo']}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                if (property['detalhes'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      property['detalhes'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
          ),
        const Divider(height: 8),
      ],
    );
  }

  Widget _buildClinicalStudiesCard(Map<String, dynamic> data) {
    final tiposEstudo = data['tiposEstudo'] as Map<String, dynamic>?;

    if (tiposEstudo == null || tiposEstudo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.indigo[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  "ESTUDOS CLÍNICOS",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...tiposEstudo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.indigo[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${_formatChemicalName(entry.key)}: ${entry.value}",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyScientificContent(Map<String, dynamic> data) {
    final String farmacologia = data['farmacologia'] ?? '';

    if (farmacologia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  "FARMACOLOGIA (Detalhes)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              farmacologia,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ABA REFERÊNCIAS ====================
  Widget _buildReferenciasTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralReferencesSection(data),
          const SizedBox(height: 24),
          _buildScientificReferencesSection(data),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildGeneralReferencesSection(Map<String, dynamic> data) {
    final refGeral = _parseListField(data['referenciaGeral']);
    final validLinks = refGeral
        .where((link) => link.trim().isNotEmpty)
        .toList();

    if (validLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              "REFERÊNCIAS GERAIS (${validLinks.length})",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...validLinks.map((link) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.link, color: Colors.green[700]),
              title: Text(
                link.length > 50 ? '${link.substring(0, 50)}...' : link,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _launchURL(link),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScientificReferencesSection(Map<String, dynamic> data) {
    // Tenta usar referências estruturadas primeiro
    final referenciasCientificas =
        data['referenciasCientificas'] as List<dynamic>?;

    if (referenciasCientificas != null && referenciasCientificas.isNotEmpty) {
      return _buildStructuredReferences(referenciasCientificas);
    }

    // Fallback para referências farmacológicas antigas
    final refFarmacologicas = _parseListField(
      data['referenciasFarmacologicas'],
    );
    final validLinks = refFarmacologicas
        .where((link) => link.trim().isNotEmpty)
        .toList();

    if (validLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              "REFERÊNCIAS CIENTÍFICAS (${validLinks.length})",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...validLinks.map((link) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.science_outlined, color: Colors.blue[700]),
              title: Text(
                link.length > 50 ? '${link.substring(0, 50)}...' : link,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _launchURL(link),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStructuredReferences(List<dynamic> referencias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              "REFERÊNCIAS CIENTÍFICAS (${referencias.length})",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...referencias.map((ref) {
          return _buildScientificReferenceCard(ref as Map<String, dynamic>);
        }),
      ],
    );
  }

  Widget _buildScientificReferenceCard(Map<String, dynamic> ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref['titulo'] ?? 'Sem título',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "${ref['autores'] ?? 'Autores desconhecidos'} • ${ref['ano'] ?? ''}",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            if (ref['pmid'] != null || ref['doi'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  ref['pmid'] != null
                      ? "PMID: ${ref['pmid']}"
                      : "DOI: ${ref['doi']}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            if (ref['citacoes'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.format_quote, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${ref['citacoes']} citações",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (ref['url'] != null)
                  TextButton.icon(
                    onPressed: () => _launchURL(ref['url'] ?? ''),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("Abrir"),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _copyReference(ref),
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text("Citar"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET AUXILIAR ====================
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    String? content,
    Widget? customContent,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content != null)
              Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
            if (customContent != null) customContent,
          ],
        ),
      ),
    );
  }

  // ==================== BUILD PRINCIPAL ====================
  @override
  Widget build(BuildContext context) {
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
    final String nomeCientifico = data['nomeCientifico'] ?? '';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: _buildPlantHeader(data),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.green[800],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                  tabs: const [
                    Tab(icon: Icon(Icons.person), text: "Geral"),
                    Tab(icon: Icon(Icons.science), text: "Científico"),
                    Tab(icon: Icon(Icons.menu_book), text: "Referências"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            if (nomeCientifico.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.grey[100],
                child: Text(
                  nomeCientifico,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
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
    );
  }
}

// ==================== DELEGATE PARA TABBAR ====================
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
