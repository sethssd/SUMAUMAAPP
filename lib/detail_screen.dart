import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart'; 

class DetailScreen extends StatefulWidget {
  final String plantaId;
  const DetailScreen({super.key, required this.plantaId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  DocumentSnapshot? _plantaData;
  bool _isLoading = true;

  final Map<String, bool> _expandedTopics = {
    'Taxonomia e nomes populares': false,
    'Descrição': false,
    'Distribuição e habitat': false,
    'Fenologia': false,
    'Usos e valor econômico': false,
    'Farmacologia': false,
    'Referências farmacológicas': false,
    'Referência geral': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPlantaData();
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

  // --- 1. FUNÇÃO DE PARSER (A CORREÇÃO) ---
  /// Converte com segurança um campo do Firestore que pode ser
  /// uma List<dynamic> ou uma única String.
  List<String> _parseListField(dynamic data) {
    if (data is List) {
      // Se já for uma lista, apenas converte os itens para String
      return data.map((item) => item.toString()).toList();
    }
    if (data is String) {
      // Se for uma String, divide por vírgula (ou apenas retorna a string)
      return data.split(',').map((e) => e.trim()).toList();
    }
    return []; // Se for nulo ou outro tipo, retorna lista vazia
  }
  // --- FIM DA CORREÇÃO ---


  // Widget para TÓPICOS DE TEXTO
  Widget _buildExpandableTextTopic(String title, String content) {
    if (content.isEmpty) {
      return const SizedBox.shrink(); 
    }
    final isExpanded = _expandedTopics[title] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _toggleExpansion(title),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET PARA TÓPICOS DE REFERÊNCIA
  Widget _buildReferenceTopic(String title, List<String> links, String plantName) {
    final validLinks = links.where((link) => link.trim().isNotEmpty).toList();

    if (validLinks.isEmpty) {
      return const SizedBox.shrink(); 
    }
    final isExpanded = _expandedTopics[title] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _toggleExpansion(title),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Text(
                  'Clique no botão para abrir o artigo relacionado ao $plantName:',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                ...validLinks.map((link) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: Text(link.length > 30 ? '${link.substring(0, 30)}...' : link),
                      onPressed: () => _launchURL(link),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
    final String imagemUrl = data['imagemUrl'] ?? '';
    final String modelo3dUrl = data['modelo3dUrl'] ?? '';

    // Campos de Texto
    final String taxonomia = data['taxonomiaNomesPopulares'] ?? '';
    final String descricao = data['descricao'] ?? data['descricaoCompleta'] ?? '';
    final String distribuicao = data['distribuicaoHabitat'] ?? '';
    final String fenologia = data['fenologia'] ?? '';
    final String usosValor = data['usosEValorEconomico'] ?? '';
    final String farmacologia = data['farmacologia'] ?? '';
    
    // --- 2. CAMPOS DE LINK (USANDO O PARSER SEGURO) ---
    final List<String> refFarmacologicas = _parseListField(data['referenciasFarmacologicas']);
    final List<String> refGeral = _parseListField(data['referenciaGeral']);

    final bool hasModel3D = modelo3dUrl.isNotEmpty;

    List<Widget> topicsList = [
      _buildExpandableTextTopic('Taxonomia e nomes populares', taxonomia),
      _buildExpandableTextTopic('Descrição', descricao),
      _buildExpandableTextTopic('Distribuição e habitat', distribuicao),
      _buildExpandableTextTopic('Fenologia', fenologia),
      _buildExpandableTextTopic('Usos e valor econômico', usosValor),
      _buildExpandableTextTopic('Farmacologia', farmacologia),
      _buildReferenceTopic('Referências farmacológicas', refFarmacologicas, nome),
      _buildReferenceTopic('Referência geral', refGeral, nome),
      const SizedBox(height: 50),
    ];

    if (hasModel3D) {
      // --- LAYOUT COM 3D ---
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(nome),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                color: Colors.grey[200],
                child: ModelViewer(
                  src: modelo3dUrl,
                  ar: false,
                  alt: nome,
                  cameraControls: true,
                  autoRotate: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                    if (nomeCientifico.isNotEmpty)
                      Text(nomeCientifico, style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(topicsList),
            ),
          ],
        ),
      );
    } else {
      // --- LAYOUT COM 2D ---
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imagemUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
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
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nome, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (nomeCientifico.isNotEmpty)
                            Text(nomeCientifico, style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(topicsList),
            ),
          ],
        ),
      );
    }
  }
}