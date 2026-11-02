import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plant_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/account/botanical_header.dart';

class _ReferenceEntry {
  final String titulo;
  final String autores;
  final String instituicaoAno;
  final String tipo;
  final String? plantaNome;
  final String? url;

  const _ReferenceEntry({
    required this.titulo,
    required this.autores,
    required this.instituicaoAno,
    this.tipo = 'Artigo',
    this.plantaNome,
    this.url,
  });
}

/// Tela de Referências Bibliográficas e Científicas — fiel a "Referências Conta.pdf".
class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key});

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'Todos';
  bool _isLoading = true;
  List<_ReferenceEntry> _references = [];

  static const List<_ReferenceEntry> _curatedBaseReferences = [
    _ReferenceEntry(
      titulo: 'Plantas medicinais da Amazônia: uso tradicional e potencial terapêutico',
      autores: 'Silva, J. K.   Oliveira, R. S.   Almeida, F. G.',
      instituicaoAno: 'Universidade Federal do Oeste do Pará, 2026.',
      tipo: 'Artigo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() => _isLoading = true);
    final list = <_ReferenceEntry>[..._curatedBaseReferences];

    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.collectionPlants)
          .limit(100)
          .get();

      for (final doc in snap.docs) {
        final plant = PlantModel.fromSnapshot(doc);
        if (plant.excluida) continue;

        // 1. Referências científicas estruturadas (mapas com titulo, autores, ano, url)
        if (plant.referenciasCientificas != null) {
          for (final raw in plant.referenciasCientificas!) {
            if (raw is Map) {
              final titulo = (raw['titulo']?.toString().trim() ?? '');
              final autores = (raw['autores']?.toString().trim() ?? 'Pesquisadores Sumaúma BioData');
              final ano = (raw['ano']?.toString().trim() ?? '2026');
              final rev = (raw['revista'] ?? raw['instituicao'] ?? 'Acervo Científico Sumaúma BioData').toString().trim();
              final url = raw['url']?.toString().trim();
              if (titulo.isNotEmpty) {
                list.add(
                  _ReferenceEntry(
                    titulo: titulo,
                    autores: autores,
                    instituicaoAno: '$rev, $ano.',
                    tipo: 'Artigo',
                    plantaNome: plant.nome,
                    url: (url != null && url.isNotEmpty) ? url : null,
                  ),
                );
              }
            }
          }
        }

        // 2. Referências farmacológicas (texto ou link)
        for (final refStr in plant.referenciasFarmacologicas) {
          final clean = refStr.trim();
          if (clean.isEmpty) continue;
          final isLink = clean.startsWith('http://') || clean.startsWith('https://');
          list.add(
            _ReferenceEntry(
              titulo: isLink
                  ? 'Estudo farmacológico e fitoquímico: ${plant.nome} (${plant.nomeCientifico})'
                  : clean,
              autores: 'Acervo Farmacológico • ${plant.nome}',
              instituicaoAno: isLink ? clean : 'Base Científica Sumaúma BioData, UFOPA.',
              tipo: 'Artigo',
              plantaNome: plant.nome,
              url: isLink ? clean : null,
            ),
          );
        }

        // 3. Referências gerais
        for (final refStr in plant.referenciaGeral) {
          final clean = refStr.trim();
          if (clean.isEmpty) continue;
          final isLink = clean.startsWith('http://') || clean.startsWith('https://');
          list.add(
            _ReferenceEntry(
              titulo: isLink
                  ? 'Referência botânica e etnobotânica: ${plant.nome}'
                  : clean,
              autores: 'Catalogação Botânica • ${plant.nome}',
              instituicaoAno: isLink ? clean : 'Herbário e Saberes da Amazônia, UFOPA.',
              tipo: 'Referência',
              plantaNome: plant.nome,
              url: isLink ? clean : null,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Aviso ao carregar referências das plantas: $e');
    }

    if (mounted) {
      setState(() {
        _references = list;
        _isLoading = false;
      });
    }
  }

  void _openFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final types = ['Todos', 'Artigo', 'Referência'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar Referências',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...types.map(
                  (t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t,
                      style: TextStyle(
                        fontWeight: _selectedType == t ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedType == t
                            ? kAccountGreen
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: _selectedType == t
                        ? const Icon(Icons.check_rounded, color: kAccountGreen)
                        : null,
                    onTap: () {
                      setState(() => _selectedType = t);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTapReference(_ReferenceEntry item) async {
    if (item.url != null && item.url!.startsWith('http')) {
      final uri = Uri.tryParse(item.url!);
      if (uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }
    final citation = '${item.autores}. ${item.titulo}. ${item.instituicaoAno}';
    await Clipboard.setData(ClipboardData(text: citation));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Citação copiada para a área de transferência.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _searchQuery.trim().toLowerCase();

    final filtered = _references.where((r) {
      final matchesType = _selectedType == 'Todos' || r.tipo == _selectedType;
      final matchesQuery = q.isEmpty ||
          r.titulo.toLowerCase().contains(q) ||
          r.autores.toLowerCase().contains(q) ||
          r.instituicaoAno.toLowerCase().contains(q) ||
          (r.plantaNome?.toLowerCase().contains(q) ?? false);
      return matchesType && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : kAccountPageBg,
      body: Column(
        children: [
          const BotanicalAppBar(
            title: 'REFERÊNCIAS',
            uppercaseTitle: true,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                // Barra de Pesquisa + Botão de Filtro (fiel a Referências Conta.pdf)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? SumaColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? SumaColors.darkDivider
                                : const Color(0xFFDCDCDC),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: isDark ? Colors.white70 : const Color(0xFF424242),
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 15.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Pesquisar',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white38 : const Color(0xFF8C8C8C),
                                    fontSize: 16,
                                  ),
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(Icons.close_rounded, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Container(
                        width: 54,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _selectedType != 'Todos'
                              ? kAccountGreen
                              : (isDark ? SumaColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _selectedType != 'Todos'
                                ? kAccountGreen
                                : (isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC)),
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _selectedType != 'Todos'
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF333333)),
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: kAccountGreen),
                    ),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(36),
                    child: Center(
                      child: Text(
                        'Nenhuma referência encontrada.',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (ref) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () => _onTapReference(ref),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? SumaColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? SumaColors.darkDivider
                                  : const Color(0xFFDCDCDC),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.titulo,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.32,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ref.autores,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : const Color(0xFF2B2B2B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ref.instituicaoAno,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : const Color(0xFF2B2B2B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SumaColors.greenAccentSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      ref.tipo,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: SumaColors.greenDeep,
                                      ),
                                    ),
                                  ),
                                  if (ref.plantaNome != null &&
                                      ref.plantaNome!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? SumaColors.darkSurface
                                            : const Color(0xFFEAF5EA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        ref.plantaNome!,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? SumaColors.greenSage
                                              : kAccountGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
