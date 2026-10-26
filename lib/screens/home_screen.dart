import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destaque_model.dart';
import '../models/plant_model.dart';
import '../screens/detail_screen.dart';
import '../widgets/home/category_chip_bar.dart';
import '../widgets/home/destaque_carousel.dart';
import '../widgets/home/noticias_tab_view.dart';
import '../widgets/home/plant_card.dart';
import '../widgets/home/popular_plants_row.dart';
import '../widgets/home/recentes_carousel.dart';
import '../widgets/home/search_filter_modal.dart';
import '../widgets/home/todas_plantas_hub_card.dart';
import '../widgets/side_menu.dart';
import '../utils/app_theme.dart';

// ── Constantes ────────────────────────────────────────────────────────────────

const int _kPageSize = 20;
const int _kPopularLimit = 6;
const int _kRecentesLimit = 10;

const List<String> _kCategories = [
  'Medicinais',
  'Frutíferas',
  'Aromáticas',
  'Madeireiras',
  'Ornamentais',
  'Alimentícias',
  'Tóxicas',
  'Aquáticas',
];

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Estado: navegação entre Home (0), Notícias (1) e Todas as Plantas (2) ──
  int _currentNavIndex = 0;
  late final PageController _tabPageController;

  // ── Estado: pesquisa inline (funciona na própria tela sem abrir outra rota) ──
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // ── Estado: paginação de plantas (aba "Todas as Plantas") ──────────────────
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _plantaDocs = [];
  DocumentSnapshot? _lastDoc;
  final ScrollController _catalogScrollController = ScrollController();

  // ── Estado: categoria e filtros selecionados ───────────────────────────────
  String? _selectedCategory;
  PlantFilterState _filterState = const PlantFilterState();

  // ── Estado: seções do Hub Inicial ──────────────────────────────────────────
  List<DestaqueModel> _destaques = [];
  List<PlantModel> _allHubPlants = [];
  List<PlantModel> _recentes = [];
  List<PlantModel> _populares = [];
  List<PlantModel> _todasPreview = [];
  bool _hubLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _currentNavIndex);
    _fetchHubData();
    _fetchPlantas(reset: true);
    _catalogScrollController.addListener(_onCatalogScroll);
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _catalogScrollController.dispose();
    super.dispose();
  }

  void _onCatalogScroll() {
    if (!_catalogScrollController.hasClients) return;
    if (_catalogScrollController.position.pixels >=
        _catalogScrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _fetchPlantas();
      }
    }
  }

  void _switchTab(int index) {
    if (_currentNavIndex == index) return;
    _searchFocusNode.unfocus();
    setState(() => _currentNavIndex = index);
    if (_tabPageController.hasClients) {
      _tabPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ── Fetch dos dados do Hub Inicial ─────────────────────────────────────────

  Future<void> _fetchHubData() async {
    List<DestaqueModel> loadedDestaques = [];
    List<PlantModel> allPlants = [];

    // 1. Busca de Destaques isolada para nunca bloquear o carregamento das plantas
    try {
      final destaquesSnap =
          await FirebaseFirestore.instance.collection('destaques').get();
      loadedDestaques = destaquesSnap.docs
          .map((d) => DestaqueModel.fromSnapshot(d))
          .toList()
        ..sort((a, b) {
          final orderCmp = a.ordem.compareTo(b.ordem);
          if (orderCmp != 0) return orderCmp;
          final dateA =
              a.dataPublicacao ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              b.dataPublicacao ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });
    } catch (e) {
      debugPrint('Aviso ao carregar destaques: $e');
    }

    // 2. Busca de Plantas (filtra excluida/isDeleted em memória para incluir
    // documentos antigos que não possuem o campo booleano no Firestore)
    try {
      final plantasSnap = await FirebaseFirestore.instance
          .collection('plantas')
          .limit(80)
          .get();

      allPlants = plantasSnap.docs
          .where((d) {
            final data = d.data() as Map<String, dynamic>?;
            return data != null &&
                data['excluida'] != true &&
                data['isDeleted'] != true;
          })
          .map((d) => PlantModel.fromSnapshot(d))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar plantas do Hub: $e');
    }

    // Populares: prioriza plantas marcadas com isPopular == true e completa até o limite
    final flaggedPopular = allPlants.where((p) => p.isPopular).toList();
    final unflaggedPopular = allPlants.where((p) => !p.isPopular).toList();
    final popularesList = [
      ...flaggedPopular,
      ...unflaggedPopular,
    ].take(_kPopularLimit).toList();

    // Adicionados: prioriza todas as plantas adicionadas até 3 dias atrás (máx 10).
    // Se houver menos de 10 adicionadas nos últimos 3 dias, preenche com as mais
    // recentes gerais para manter sempre 10 plantas na amostragem do Hub.
    final now = DateTime.now();
    final sortedByDate = List<PlantModel>.from(allPlants)
      ..sort((a, b) {
        final dateA =
            a.dataCriacao ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            b.dataCriacao ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    final addedLast3Days = <PlantModel>[];
    final olderPlants = <PlantModel>[];

    for (final plant in sortedByDate) {
      final refDate = plant.dataCriacao ?? plant.updatedAt;
      if (refDate != null && now.difference(refDate).inDays <= 3) {
        addedLast3Days.add(plant);
      } else {
        olderPlants.add(plant);
      }
    }

    final recentesList = <PlantModel>[
      ...addedLast3Days,
      ...olderPlants,
    ].take(_kRecentesLimit).toList();

    if (!mounted) return;
    setState(() {
      _destaques = loadedDestaques;
      _allHubPlants = allPlants;
      _populares = popularesList;
      _todasPreview = allPlants.take(3).toList();
      _recentes = recentesList;
      _hubLoaded = true;
    });
  }

  // ── Fetch paginado de plantas para a aba "Todas as Plantas" ────────────────

  Future<void> _fetchPlantas({bool reset = false}) async {
    if (_isLoadingMore) return;

    if (reset) {
      setState(() {
        _isInitialLoading = true;
        _plantaDocs.clear();
        _lastDoc = null;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('plantas')
          .limit(_kPageSize);

      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        query = FirebaseFirestore.instance
            .collection('plantas')
            .where('categoria', isEqualTo: _selectedCategory)
            .limit(_kPageSize);
      }

      if (_lastDoc != null && !reset) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < _kPageSize) _hasMore = false;
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        final validDocs = snapshot.docs.where((d) {
          final data = d.data() as Map<String, dynamic>?;
          return data != null &&
              data['excluida'] != true &&
              data['isDeleted'] != true;
        });
        _plantaDocs.addAll(validDocs);
      }
    } catch (e) {
      debugPrint('Erro ao carregar plantas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onCategorySelected(String? cat) {
    if (_selectedCategory == cat) return;
    setState(() {
      _selectedCategory = cat;
      _filterState = _filterState.copyWith(
        tipos: cat != null && cat.isNotEmpty ? {cat} : <String>{},
      );
    });
    _fetchPlantas(reset: true);
  }

  Future<void> _openFilterModal() async {
    _searchFocusNode.unfocus();
    final result = await showSearchFilterModal(
      context: context,
      initialState: _filterState,
      onChanged: (updated) {
        if (!mounted) return;
        setState(() {
          _filterState = updated;
          _selectedCategory =
              updated.tipos.length == 1 ? updated.tipos.first : null;
        });
      },
    );
    if (result != null && mounted) {
      setState(() {
        _filterState = result;
        _selectedCategory =
            result.tipos.length == 1 ? result.tipos.first : null;
      });
      _fetchPlantas(reset: true);
    }
  }

  // ── Filtro inline de busca ─────────────────────────────────────────────────

  bool _matchesSearch(PlantModel plant, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (plant.nome.toLowerCase().contains(q)) return true;
    if (plant.nomeCientifico.toLowerCase().contains(q)) return true;
    if (plant.categoria.toLowerCase().contains(q)) return true;
    if (plant.resumoLimpo.toLowerCase().contains(q)) return true;
    if (plant.keywords.any((k) => k.toLowerCase().contains(q))) return true;
    if (plant.aspectosUso.any((a) => a.toLowerCase().contains(q))) return true;
    return false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? SumaColors.darkBg : SumaColors.lightBg,
        drawer: const SideMenu(),
        body: !_hubLoaded && _isInitialLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? SumaColors.greenSage : SumaColors.greenAccent,
                ),
              )
            : SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Conteúdo principal se estende até o fundo da tela por trás da curva da barra inferior
                    Column(
                      children: [
                        _buildTopHeader(isDark),
                        Expanded(
                          child: PageView(
                            controller: _tabPageController,
                            onPageChanged: (index) {
                              if (_currentNavIndex != index) {
                                _searchFocusNode.unfocus();
                                setState(() => _currentNavIndex = index);
                              }
                            },
                            children: [
                              _buildHubTab(isDark),
                              NoticiasTabView(
                                destaques: _destaques,
                                onRefresh: _fetchHubData,
                              ),
                              _buildAllPlantsCatalogTab(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Barra inferior flutuante com onda suave (sem cantos brancos cortando o scroll)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildBottomNavBar(isDark),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Cabeçalho superior com menu hambúrguer, avatar e pesquisa inline ───────

  Widget _buildTopHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Linha 1: menu hambúrguer + avatar circular
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(builder: (ctx) {
                return GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.menu_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 32,
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Use o menu lateral para gerenciar sua conta.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white24 : Colors.black,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Linha 2: Barra de busca inline (funciona direto na tela) + botão de filtro
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: isDark ? null : SumaGradients.searchBar,
                    color: isDark ? SumaColors.darkSurface : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Pesquise aqui',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
                            _searchFocusNode.unfocus();
                            setState(() => _searchQuery = '');
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botão de filtro que abre o modal "Filtro de Pesquisa"
              GestureDetector(
                onTap: _openFilterModal,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 50,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? null
                            : (_filterState.hasActiveFilters
                                ? SumaGradients.filterActive
                                : SumaGradients.searchBar),
                        color: isDark
                            ? (_filterState.hasActiveFilters
                                ? SumaColors.greenAccentDark
                                : SumaColors.darkSurface)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        border: _filterState.hasActiveFilters
                            ? Border.all(color: SumaColors.greenSage, width: 1.8)
                            : null,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    if (_filterState.hasActiveFilters)
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: isDark ? null : SumaGradients.searchBar,
                            color: isDark ? SumaColors.greenAccent : null,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? SumaColors.darkBg : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${_filterState.activeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Aba 0: Hub Inicial (Home) ──────────────────────────────────────────────

  Widget _buildHubTab(bool isDark) {
    final query = _searchQuery.trim();
    final hasFilters = _filterState.hasActiveFilters;
    final showInlineResults = query.isNotEmpty || hasFilters;
    final searchResults = !showInlineResults
        ? const <PlantModel>[]
        : (_allHubPlants
            .where((p) => _matchesSearch(p, query) && _filterState.matchesPlant(p))
            .toList()
          ..sort((a, b) => _filterState.matchScore(b).compareTo(_filterState.matchScore(a))));

    return RefreshIndicator(
      onRefresh: _fetchHubData,
      child: ListView(
        padding: const EdgeInsets.only(top: 6),
        children: [
          // Resultados da pesquisa e/ou filtros inline diretamente no Hub (sem mudar de tela)
          if (showInlineResults) ...[
            _buildInlineSearchResults(searchResults, query, isDark),
            const SizedBox(height: 20),
          ],

          // 1. Card "Popular"
          if (_populares.isNotEmpty) ...[
            PopularPlantsRow(plantas: _populares),
            const SizedBox(height: 22),
          ],

          // 2. Bloco "Toda as Plantas" com acordeão "Principais Aspectos"
          if (_todasPreview.isNotEmpty) ...[
            TodasPlantasHubCard(
              plantas: _todasPreview,
              onSeeAllTap: () => _switchTab(2),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Carrossel "Destaques" com animação de escala ao arrastar
          if (_destaques.isNotEmpty) ...[
            DestaqueCarousel(destaques: _destaques),
            const SizedBox(height: 26),
          ],

          // 4. Seção "Adicionados" (exibe 4 no Hub e abre a tela com as 10 recentes em "Explorar")
          if (_recentes.isNotEmpty)
            RecentesCarousel(
              plantas: _recentes,
              title: 'Adicionados',
            ),
        ],
      ),
    );
  }

  Widget _buildInlineSearchResults(
    List<PlantModel> results,
    String query,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? SumaColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? SumaColors.greenSage : SumaColors.greenAccent)
              .withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  query.isNotEmpty
                      ? 'Resultados para "$query" (${results.length})'
                      : 'Plantas filtradas (${results.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? SumaColors.greenSage : SumaColors.greenAccent,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() {
                    _searchQuery = '';
                    _filterState = const PlantFilterState();
                    _selectedCategory = null;
                  });
                  _fetchPlantas(reset: true);
                },
                child: Text(
                  'Limpar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (_filterState.hasActiveFilters) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterState.activeLabels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _filterState.activeLabels[index];
                  final iconType = iconTypeForFilterLabel(label);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterState = _filterState.removeFilter(label);
                        _selectedCategory = _filterState.tipos.length == 1
                            ? _filterState.tipos.first
                            : null;
                      });
                      _fetchPlantas(reset: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(5, 4, 9, 4),
                      decoration: BoxDecoration(
                        gradient: isDark ? null : SumaGradients.aspectPill,
                        color: isDark ? SumaColors.greenAccent : null,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? SumaColors.greenAccent
                                    : const Color(0xFF245F30))
                                .withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CustomPaint(
                                size: const Size(15, 15),
                                painter: FilterIconPainter(
                                  type: iconType,
                                  color: SumaColors.greenAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhuma planta encontrada com os filtros selecionados.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            )
          else
            ...results.take(6).map((plant) {
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(plantaId: plant.id),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: plant.imagemUrl.isNotEmpty
                              ? Image.network(
                                  plant.imagemUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: SumaColors.greenDeep,
                                    child: const Icon(
                                      Icons.eco_rounded,
                                      color: Colors.white54,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: SumaColors.greenDeep,
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    color: Colors.white54,
                                    size: 22,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.nome,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            if (plant.nomeCientifico.isNotEmpty)
                              Text(
                                plant.nomeCientifico,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: SumaColors.greenBright,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? SumaColors.greenSage
                            : SumaColors.greenAccent,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Aba 2: Catálogo Completo ("Todas as Plantas") ──────────────────────────

  Widget _buildAllPlantsCatalogTab(bool isDark) {
    final allLoaded = _plantaDocs.map((doc) {
      try {
        return PlantModel.fromSnapshot(doc);
      } catch (_) {
        return null;
      }
    }).whereType<PlantModel>().toList();

    final plantas = allLoaded.where((p) {
      final matchesText = _searchQuery.trim().isEmpty || _matchesSearch(p, _searchQuery);
      return matchesText && _filterState.matchesPlant(p);
    }).toList();

    return CustomScrollView(
      controller: _catalogScrollController,
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              _selectedCategory != null
                  ? 'Plantas: $_selectedCategory'
                  : 'Todas as Plantas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? SumaColors.greenSage : SumaColors.greenAccent,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CategoryChipBar(
              categories: _kCategories,
              selected: _selectedCategory,
              onSelected: _onCategorySelected,
            ),
          ),
        ),
        _isInitialLoading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            : plantas.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory != null
                                ? 'Nenhuma planta em "$_selectedCategory".'
                                : 'Nenhuma planta encontrada.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == plantas.length) {
                          return _hasMore && _searchQuery.trim().isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Todas as plantas carregadas.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                );
                        }
                        return PlantCard(plant: plantas[index]);
                      },
                      childCount: plantas.length + 1,
                    ),
                  ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }

  // ── Barra de Navegação Inferior em Onda Suave com Círculo Verde Centralizado ──

  Widget _buildBottomNavBar(bool isDark) {
    final Color barBgColor = isDark ? SumaColors.darkCard : Colors.white;
    final Color borderColor = isDark
        ? SumaColors.darkDivider
        : SumaColors.greenAccent.withValues(alpha: 0.18);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _currentNavIndex.toDouble()),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, animatedIndex, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            const double horizontalPadding = 12.0;
            final double slotWidth = (totalWidth - horizontalPadding * 2) / 3;
            final double waveCenterX =
                horizontalPadding + slotWidth * (animatedIndex + 0.5);

            // Geometria vertical:
            // y = 0: topo da crista da onda branca
            // y = 20: linha reta superior da barra branca (waveHeight = 20)
            // Círculo verde (48x48): topo em y = 6, centro em y = 30, base em y = 54
            // Rótulos: iniciam em y = 57 até y = 89
            const double waveHeight = 20.0;
            const double barBodyHeight = 72.0;
            const double totalHeight = waveHeight + barBodyHeight;

            return SizedBox(
              width: totalWidth,
              height: totalHeight + bottomInset,
              child: CustomPaint(
                painter: _WaveBottomBarPainter(
                  waveCenterX: waveCenterX,
                  waveHeight: waveHeight,
                  fillColor: barBgColor,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: bottomInset,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Único círculo verde perfeitamente no centro da onda
                      Positioned(
                        top: 6,
                        left: (slotWidth * animatedIndex) + (slotWidth - 48) / 2,
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isDark ? null : SumaGradients.bottomNavActiveCircle,
                            color: isDark ? SumaColors.greenAccent : null,
                            boxShadow: [
                              BoxShadow(
                                color: SumaColors.greenAccent.withValues(alpha: 0.32),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Ícones e rótulos das 3 abas
                      Row(
                        children: [
                          Expanded(
                            child: _BottomNavItem(
                              icon: Icons.home_outlined,
                              label: 'Home',
                              isSelected: _currentNavIndex == 0,
                              isDark: isDark,
                              onTap: () => _switchTab(0),
                            ),
                          ),
                          Expanded(
                            child: _BottomNavItem(
                              icon: Icons.description_outlined,
                              label: 'Notícias',
                              isSelected: _currentNavIndex == 1,
                              isDark: isDark,
                              onTap: () => _switchTab(1),
                            ),
                          ),
                          Expanded(
                            child: _BottomNavItem(
                              icon: Icons.apps_rounded,
                              label: 'Todas as\nPlantas',
                              isSelected: _currentNavIndex == 2,
                              isDark: isDark,
                              onTap: () => _switchTab(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Desenha o fundo branco da barra inferior com cantos arredondados e a onda
/// suave de pontas redondas acompanhando o botão ativo.
class _WaveBottomBarPainter extends CustomPainter {
  final double waveCenterX;
  final double waveHeight;
  final Color fillColor;
  final Color borderColor;
  final bool isDark;

  const _WaveBottomBarPainter({
    required this.waveCenterX,
    required this.waveHeight,
    required this.fillColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerRadius = 26.0;
    const double waveHalfWidth = 54.0;

    final double leftStart = (waveCenterX - waveHalfWidth).clamp(cornerRadius, size.width - cornerRadius);
    final double rightEnd = (waveCenterX + waveHalfWidth).clamp(cornerRadius, size.width - cornerRadius);

    final Path path = Path();

    // Inicia na base esquerda e sobe até a curva do canto superior esquerdo
    path.moveTo(0, size.height);
    path.lineTo(0, waveHeight + cornerRadius);
    path.quadraticBezierTo(0, waveHeight, cornerRadius, waveHeight);

    // Linha superior até o início da onda
    if (leftStart > cornerRadius) {
      path.lineTo(leftStart, waveHeight);
    }

    // Subida suave da onda com ombros bem redondos até o topo (waveCenterX, 0)
    path.cubicTo(
      waveCenterX - waveHalfWidth * 0.52,
      waveHeight,
      waveCenterX - waveHalfWidth * 0.46,
      0,
      waveCenterX,
      0,
    );

    // Descida simétrica da onda de volta para a linha da barra (waveHeight)
    path.cubicTo(
      waveCenterX + waveHalfWidth * 0.46,
      0,
      waveCenterX + waveHalfWidth * 0.52,
      waveHeight,
      rightEnd,
      waveHeight,
    );

    // Linha superior até o canto superior direito
    if (rightEnd < size.width - cornerRadius) {
      path.lineTo(size.width - cornerRadius, waveHeight);
    }
    path.quadraticBezierTo(
      size.width,
      waveHeight,
      size.width,
      waveHeight + cornerRadius,
    );

    // Desce até a base direita e fecha
    path.lineTo(size.width, size.height);
    path.close();

    // Sombra suave projetada para cima
    canvas.save();
    canvas.translate(0, -3);
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
      8.0,
      false,
    );
    canvas.restore();

    // Preenchimento branco (ou darkCard)
    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);

    // Contorno superior sutil acompanhando a curva e a onda
    final Path borderPath = Path()
      ..moveTo(0, waveHeight + cornerRadius)
      ..quadraticBezierTo(0, waveHeight, cornerRadius, waveHeight);
    if (leftStart > cornerRadius) {
      borderPath.lineTo(leftStart, waveHeight);
    }
    borderPath
      ..cubicTo(
        waveCenterX - waveHalfWidth * 0.52,
        waveHeight,
        waveCenterX - waveHalfWidth * 0.46,
        0,
        waveCenterX,
        0,
      )
      ..cubicTo(
        waveCenterX + waveHalfWidth * 0.46,
        0,
        waveCenterX + waveHalfWidth * 0.52,
        waveHeight,
        rightEnd,
        waveHeight,
      );
    if (rightEnd < size.width - cornerRadius) {
      borderPath.lineTo(size.width - cornerRadius, waveHeight);
    }
    borderPath.quadraticBezierTo(
      size.width,
      waveHeight,
      size.width,
      waveHeight + cornerRadius,
    );

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveBottomBarPainter oldDelegate) {
    return oldDelegate.waveCenterX != waveCenterX ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.isDark != isDark;
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? Colors.white54 : SumaColors.lightTextMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 92,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ícone: quando selecionado fica exatamente no centro do círculo verde (y = 30, topo = 6, altura = 48);
            // quando inativo fica suavemente mais abaixo na área plana da barra
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              top: isSelected ? 6 : 22,
              height: isSelected ? 48 : 34,
              left: 0,
              right: 0,
              child: Center(
                child: Icon(
                  icon,
                  size: 26,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),
            ),

            // Rótulo alinhado abaixo do círculo verde (top = 57), sem sobreposição e sem overflow
            Positioned(
              top: 57,
              left: 2,
              right: 2,
              bottom: 2,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSelected ? 12.5 : 10.5,
                    height: 1.05,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? SumaColors.greenSage : SumaColors.greenAccent)
                        : inactiveColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
