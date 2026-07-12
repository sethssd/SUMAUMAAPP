import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destaque_model.dart';
import '../models/plant_model.dart';
import '../widgets/home/category_chip_bar.dart';
import '../widgets/home/destaque_carousel.dart';
import '../widgets/home/plant_card.dart';
import '../widgets/home/recentes_carousel.dart';
import '../widgets/plant_search_delegate.dart';
import '../widgets/side_menu.dart';
import '../utils/app_theme.dart';

// ── Constantes ────────────────────────────────────────────────────────────────

const int _kPageSize = 20;
const int _kRecentesLimit = 10;

// Categorias exibidas nos chips. Pode ser ampliada sem alterar a lógica.
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
  // ── Estado: paginação de plantas ──────────────────────────
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _plantaDocs = [];
  DocumentSnapshot? _lastDoc;
  final ScrollController _scrollController = ScrollController();

  // ── Estado: categoria selecionada ─────────────────────────
  String? _selectedCategory;

  // ── Estado: carrosséis ────────────────────────────────────
  List<DestaqueModel> _destaques = [];
  List<PlantModel> _recentes = [];
  bool _carouselLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchCarousels();
    _fetchPlantas(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _fetchPlantas();
      }
    }
  }

  // ── Fetch destaques + recentes (paralelo) ─────────────────

  Future<void> _fetchCarousels() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('destaques')
            .orderBy('ordem')
            .get(),
        FirebaseFirestore.instance
            .collection('plantas')
            .where('excluida', isNotEqualTo: true)
            .orderBy('dataCriacao', descending: true)
            .limit(_kRecentesLimit)
            .get(),
      ]);

      final destaquesDocs = results[0].docs;
      final recentesDocs = results[1].docs;

      if (!mounted) return;
      setState(() {
        _destaques = destaquesDocs
            .map((d) => DestaqueModel.fromSnapshot(d))
            .toList();
        _recentes = recentesDocs
            .where((d) {
              final data = d.data() as Map<String, dynamic>?;
              return data != null && data['excluida'] != true;
            })
            .map((d) => PlantModel.fromSnapshot(d))
            .toList();
        _carouselLoaded = true;
      });
    } catch (e) {
      debugPrint('Erro ao carregar carrosséis: $e');
      if (mounted) setState(() => _carouselLoaded = true);
    }
  }

  // ── Fetch paginado de plantas com filtro de categoria ──────

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
          .where('excluida', isNotEqualTo: true)
          .limit(_kPageSize);

      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        query = FirebaseFirestore.instance
            .collection('plantas')
            .where('excluida', isNotEqualTo: true)
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
        _plantaDocs.addAll(snapshot.docs);
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
    setState(() => _selectedCategory = cat);
    _fetchPlantas(reset: true);
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sumaúma'),
        leading: Builder(builder: (ctx) {
          return GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                isDark ? 'icons/ico-branco.png' : 'icons/ico-verde.png',
                fit: BoxFit.contain,
              ),
            ),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar',
            onPressed: () =>
                showSearch(context: context, delegate: PlantSearchDelegate()),
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: _isInitialLoading && !_carouselLoaded
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final plantas = _plantaDocs.map((doc) {
      try {
        return PlantModel.fromSnapshot(doc);
      } catch (_) {
        return null;
      }
    }).whereType<PlantModel>().toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // ── Espaço inicial ─────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Carrossel Destaques ────────────────────────────
        if (_destaques.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: DestaqueCarousel(destaques: _destaques),
            ),
          ),

        // ── Carrossel Adicionados Recentemente ─────────────
        if (_recentes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: RecentesCarousel(plantas: _recentes),
            ),
          ),

        // ── Cabeçalho "Todas as Plantas" ───────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: SumaColors.greenBright,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory != null
                      ? _selectedCategory!.toUpperCase()
                      : 'TODAS AS PLANTAS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white70 : SumaColors.greenDeep,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Chips de categoria ─────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CategoryChipBar(
              categories: _kCategories,
              selected: _selectedCategory,
              onSelected: _onCategorySelected,
            ),
          ),
        ),

        // ── Lista de plantas ───────────────────────────────
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
                                : 'Nenhuma planta cadastrada.',
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
                          // Carregador de "página seguinte"
                          return _hasMore
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
                                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                                    ),
                                  ),
                                );
                        }
                        return PlantCard(plant: plantas[index]);
                      },
                      childCount: plantas.length + 1,
                    ),
                  ),

        // ── Padding final ─────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
