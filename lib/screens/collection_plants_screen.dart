import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../screens/detail_screen.dart';
import '../services/account_library_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/account/botanical_header.dart';
import '../widgets/home/search_filter_modal.dart';

enum CollectionPlantsMode {
  collection,
  offline,
  myPublications,
  underAnalysis,
}

enum _SortOption {
  recentes,
  alfabeticaAZ,
  alfabeticaZA,
}

/// Tela de plantas de uma Coleção, Offline, Minhas Publicações ou Em Análise.
/// Implementa fielmente os layouts em Lista ("Plantas Coleções Conta.pdf")
/// e em Grade 2 colunas ("Plantas Coleções Conta 1.pdf").
class CollectionPlantsScreen extends StatefulWidget {
  final String title;
  final CollectionPlantsMode mode;
  final String? collectionId;

  const CollectionPlantsScreen({
    super.key,
    required this.title,
    required this.mode,
    this.collectionId,
  });

  @override
  State<CollectionPlantsScreen> createState() => _CollectionPlantsScreenState();
}

class _CollectionPlantsScreenState extends State<CollectionPlantsScreen> {
  final _service = AccountLibraryService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isGridView = false;
  _SortOption _sortOption = _SortOption.recentes;
  PlantFilterState _filterState = const PlantFilterState();

  bool _isLoading = true;
  List<PlantModel> _plants = [];
  Map<String, dynamic>? _pendingRoleRequest;
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _loadData();
    if (widget.mode == CollectionPlantsMode.offline) {
      _service.offlinePlantsNotifier.addListener(_onOfflineUpdated);
    }
  }

  @override
  void dispose() {
    if (widget.mode == CollectionPlantsMode.offline) {
      _service.offlinePlantsNotifier.removeListener(_onOfflineUpdated);
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onOfflineUpdated() {
    if (!mounted) return;
    setState(() {
      _plants = _service.offlinePlantsNotifier.value.values.toList();
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _service.ensureInitialized();

      if (widget.mode == CollectionPlantsMode.offline) {
        _plants = _service.offlinePlantsNotifier.value.values.toList();
      } else if (widget.mode == CollectionPlantsMode.collection &&
          widget.collectionId != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final colSnap = await FirebaseFirestore.instance
              .collection(AppConstants.collectionUsers)
              .doc(uid)
              .collection('colecoes')
              .doc(widget.collectionId)
              .get();
          if (colSnap.exists) {
            final col = PlantCollectionModel.fromDoc(colSnap);
            _currentTitle = col.nome;
            final loaded = <PlantModel>[];
            for (final pid in col.plantIds) {
              // Tenta buscar offline primeiro caso sem rede, depois Firestore
              final cached = _service.getOfflinePlant(pid);
              try {
                final snap = await FirebaseFirestore.instance
                    .collection(AppConstants.collectionPlants)
                    .doc(pid)
                    .get();
                if (snap.exists) {
                  loaded.add(PlantModel.fromSnapshot(snap));
                } else if (cached != null) {
                  loaded.add(cached);
                }
              } catch (_) {
                if (cached != null) loaded.add(cached);
              }
            }
            _plants = loaded;
          }
        }
      } else if (widget.mode == CollectionPlantsMode.myPublications ||
          widget.mode == CollectionPlantsMode.underAnalysis) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final snap = await FirebaseFirestore.instance
            .collection(AppConstants.collectionPlants)
            .get();
        final all = snap.docs
            .map((d) => PlantModel.fromSnapshot(d))
            .where((p) => !p.excluida)
            .toList();

        if (widget.mode == CollectionPlantsMode.myPublications) {
          final mine = all.where((p) => uid != null && p.creatorId == uid && !p.isUnderAnalysis).toList();
          _plants = mine;
        } else {
          final inAnalysis = all.where((p) {
            if (uid != null && p.creatorId == uid && p.isUnderAnalysis) {
              return true;
            }
            return p.isUnderAnalysis;
          }).toList();
          _plants = inAnalysis;

          if (uid != null) {
            final reqDoc = await FirebaseFirestore.instance
                .collection('role_requests')
                .doc(uid)
                .get();
            if (reqDoc.exists) {
              _pendingRoleRequest = reqDoc.data();
            } else {
              _pendingRoleRequest = null;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar plantas da lista: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openFilterModal() async {
    final result = await showSearchFilterModal(
      context: context,
      initialState: _filterState,
      onChanged: (updated) {
        if (mounted) setState(() => _filterState = updated);
      },
    );
    if (result != null && mounted) {
      setState(() => _filterState = result);
    }
  }

  List<PlantModel> get _filteredPlants {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = _plants.where((p) {
      final matchesText = q.isEmpty ||
          p.nome.toLowerCase().contains(q) ||
          p.nomeCientifico.toLowerCase().contains(q) ||
          p.categoria.toLowerCase().contains(q) ||
          p.enderecoPrincipal.toLowerCase().contains(q);
      return matchesText && _filterState.matchesPlant(p);
    }).toList();

    switch (_sortOption) {
      case _SortOption.recentes:
        filtered.sort((a, b) {
          final da = a.dataCriacao ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.dataCriacao ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        break;
      case _SortOption.alfabeticaAZ:
        filtered.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        break;
      case _SortOption.alfabeticaZA:
        filtered.sort((a, b) => b.nome.toLowerCase().compareTo(a.nome.toLowerCase()));
        break;
    }
    return filtered;
  }

  String _sortLabel(_SortOption opt) {
    switch (opt) {
      case _SortOption.recentes:
        return 'Mais recentes';
      case _SortOption.alfabeticaAZ:
        return 'Ordem A-Z';
      case _SortOption.alfabeticaZA:
        return 'Ordem Z-A';
    }
  }

  Future<void> _removePlantFromCurrentContext(PlantModel plant) async {
    if (widget.mode == CollectionPlantsMode.collection &&
        widget.collectionId != null) {
      await _service.togglePlantInCollection(widget.collectionId!, plant.id);
      setState(() {
        _plants.removeWhere((p) => p.id == plant.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plant.nome} removida de $_currentTitle.')),
        );
      }
    } else if (widget.mode == CollectionPlantsMode.offline) {
      await _service.removeOfflinePlant(plant.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plant.nome} removida do modo Offline.')),
        );
      }
    } else {
      await _service.showSavePlantModal(context, plant);
    }
  }

  void _showTopMenu() {
    if (widget.mode != CollectionPlantsMode.collection ||
        widget.collectionId == null) {
      _loadData();
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDefault = widget.collectionId == 'favoritos';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded, color: kAccountGreen),
                title: const Text('Adicionar plantas a esta coleção'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddPlantsToCollectionDialog();
                },
              ),
              if (!isDefault) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Renomear coleção'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _promptRenameCollection();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text(
                    'Excluir coleção',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _service.deleteCollection(widget.collectionId!);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptRenameCollection() async {
    final ctrl = TextEditingController(text: _currentTitle);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear coleção'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome da coleção'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kAccountGreen),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && widget.collectionId != null) {
      await _service.renameCollection(widget.collectionId!, newName);
      if (mounted) setState(() => _currentTitle = newName);
    }
  }

  Future<void> _showAddPlantsToCollectionDialog() async {
    if (widget.collectionId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.collectionPlants)
        .limit(80)
        .get();
    final allPlants = snap.docs
        .map((d) => PlantModel.fromSnapshot(d))
        .where((p) => !p.excluida)
        .toList();

    if (!mounted) return;
    final currentIds = _plants.map((p) => p.id).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Adicionar em $_currentTitle',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollCtrl,
                          itemCount: allPlants.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, idx) {
                            final plant = allPlants[idx];
                            final selected = currentIds.contains(plant.id);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: plant.imagemUrl.isNotEmpty
                                      ? Image.network(
                                          plant.imagemUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: kAccountGreen,
                                            child: const Icon(Icons.eco, color: Colors.white),
                                          ),
                                        )
                                      : Container(
                                          color: kAccountGreen,
                                          child: const Icon(Icons.eco, color: Colors.white),
                                        ),
                                ),
                              ),
                              title: Text(
                                plant.nome,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                plant.nomeCientifico,
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              ),
                              trailing: Icon(
                                selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                color: selected ? kAccountGreen : Colors.grey,
                                size: 26,
                              ),
                              onTap: () async {
                                final added = await _service.togglePlantInCollection(
                                  widget.collectionId!,
                                  plant.id,
                                );
                                setModalState(() {
                                  if (added) {
                                    currentIds.add(plant.id);
                                  } else {
                                    currentIds.remove(plant.id);
                                  }
                                });
                                _loadData();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _filteredPlants;
    final totalCount = items.length + (_pendingRoleRequest != null ? 1 : 0);

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : kAccountPageBg,
      body: Column(
        children: [
          BotanicalAppBar(
            title: _currentTitle,
            trailing: IconButton(
              onPressed: _showTopMenu,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: kAccountGreen,
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                      child: Column(
                        children: [
                          // Linha 1: Barra de Pesquisa + Botão de Filtro (fiel a Plantas Coleções Conta.pdf)
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
                                onTap: _openFilterModal,
                                child: Container(
                                  width: 54,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _filterState.hasActiveFilters
                                        ? kAccountGreen
                                        : (isDark ? SumaColors.darkCard : Colors.white),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _filterState.hasActiveFilters
                                          ? kAccountGreen
                                          : (isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC)),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: _filterState.hasActiveFilters
                                        ? Colors.white
                                        : (isDark ? Colors.white : const Color(0xFF333333)),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Linha 2: Ordenação ("Mais recentes v") + Contador + Toggle Lista / Grade
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PopupMenuButton<_SortOption>(
                                initialValue: _sortOption,
                                onSelected: (opt) => setState(() => _sortOption = opt),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: _SortOption.recentes,
                                    child: Text('Mais recentes'),
                                  ),
                                  PopupMenuItem(
                                    value: _SortOption.alfabeticaAZ,
                                    child: Text('Ordem A-Z'),
                                  ),
                                  PopupMenuItem(
                                    value: _SortOption.alfabeticaZA,
                                    child: Text('Ordem Z-A'),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? SumaColors.darkCard : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? SumaColors.darkDivider
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _sortLabel(_sortOption),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: isDark ? Colors.white70 : const Color(0xFF1F1F1F),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Row(
                                children: [
                                  Text(
                                    '$totalCount ${totalCount == 1 ? 'item' : 'itens'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : const Color(0xFF7A7A7A),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Botão Visão em Lista
                                  GestureDetector(
                                    onTap: () => setState(() => _isGridView = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 44,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: !_isGridView
                                            ? kAccountGreen
                                            : (isDark ? SumaColors.darkCard : Colors.white),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: !_isGridView
                                              ? kAccountGreen
                                              : (isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC)),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.format_list_bulleted_rounded,
                                        size: 20,
                                        color: !_isGridView
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : const Color(0xFF333333)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Botão Visão em Grade (Cards)
                                  GestureDetector(
                                    onTap: () => setState(() => _isGridView = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 44,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _isGridView
                                            ? kAccountGreen
                                            : (isDark ? SumaColors.darkCard : Colors.white),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: _isGridView
                                              ? kAccountGreen
                                              : (isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC)),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.featured_video_outlined,
                                        size: 19,
                                        color: _isGridView
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : const Color(0xFF333333)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_pendingRoleRequest != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? SumaColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/conta/relogio.png',
                                width: 28,
                                height: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Solicitação de Perfil de Pesquisador',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Status: Em análise pela equipe Sumaúma BioData',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF39C38),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Pendente',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: kAccountGreen),
                      ),
                    )
                  else if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_outlined,
                                size: 64,
                                color: isDark ? Colors.white24 : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _emptyMessage(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                              if (widget.mode == CollectionPlantsMode.collection) ...[
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kAccountGreen,
                                  ),
                                  onPressed: _showAddPlantsToCollectionDialog,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Adicionar Plantas'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_isGridView)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _CollectionPlantGridCard(
                            plant: items[index],
                            isDark: isDark,
                            onTap: () => _openPlantDetail(items[index]),
                            onBookmarkTap: () => _removePlantFromCurrentContext(items[index]),
                            onMoreTap: () => _showPlantItemOptions(items[index]),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CollectionPlantListCard(
                              plant: items[index],
                              isDark: isDark,
                              onTap: () => _openPlantDetail(items[index]),
                              onBookmarkTap: () => _removePlantFromCurrentContext(items[index]),
                              onMoreTap: () => _showPlantItemOptions(items[index]),
                            ),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessage() {
    switch (widget.mode) {
      case CollectionPlantsMode.collection:
        return 'Nenhuma planta salva em "$_currentTitle" ainda.';
      case CollectionPlantsMode.offline:
        return 'Você ainda não baixou fichas de plantas para leitura Offline.\nAbra qualquer planta e toque no ícone de salvar/baixar.';
      case CollectionPlantsMode.myPublications:
        return 'Você ainda não possui publicações ativas vinculadas à sua conta.';
      case CollectionPlantsMode.underAnalysis:
        return _pendingRoleRequest != null
            ? 'Nenhuma planta em revisão no momento.'
            : 'Nenhum item em análise no momento.';
    }
  }

  void _openPlantDetail(PlantModel plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          plantaId: plant.id,
          offlineFallbackPlant: plant,
        ),
      ),
    );
  }

  void _showPlantItemOptions(PlantModel plant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: kAccountGreen),
                title: Text('Abrir ficha de ${plant.nome}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPlantDetail(plant);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined, color: kAccountGreen),
                title: const Text('Gerenciar em Coleções / Offline'),
                onTap: () {
                  Navigator.pop(ctx);
                  _service.showSavePlantModal(context, plant);
                },
              ),
              if (widget.mode == CollectionPlantsMode.collection ||
                  widget.mode == CollectionPlantsMode.offline)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: Text(
                    widget.mode == CollectionPlantsMode.offline
                        ? 'Remover dos baixados Offline'
                        : 'Remover de $_currentTitle',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePlantFromCurrentContext(plant);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Card horizontal da Visão em Lista (fiel a "Plantas Coleções Conta.pdf").
class _CollectionPlantListCard extends StatelessWidget {
  final PlantModel plant;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onMoreTap;

  const _CollectionPlantListCard({
    required this.plant,
    required this.isDark,
    required this.onTap,
    required this.onBookmarkTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final locationText = plant.enderecoPrincipal.isNotEmpty
        ? plant.enderecoPrincipal
        : (plant.categoria.isNotEmpty ? plant.categoria : 'Santarém - PA, Amazônia');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: isDark ? SumaColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC),
          ),
        ),
        child: Row(
          children: [
            // Foto na esquerda ocupando toda a altura do card
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(13),
              ),
              child: SizedBox(
                width: 112,
                height: 112,
                child: plant.imagemUrl.isNotEmpty
                    ? Image.network(
                        plant.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackThumb(),
                      )
                    : _fallbackThumb(),
              ),
            ),

            // Conteúdo à direita
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Linha superior: Nome + Bookmark + 3 pontos
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                                ),
                              ),
                              if (plant.nomeCientifico.isNotEmpty)
                                Text(
                                  plant.nomeCientifico,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.white70 : const Color(0xFF333333),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onBookmarkTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(
                              Icons.bookmark_border_rounded,
                              size: 21,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onMoreTap,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, top: 2),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 21,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Linha de localização
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white70 : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Pílulas verdes na base: Áudio, Modelo 3D e •••
                    _PlantFeaturePillsRow(plant: plant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      color: SumaColors.greenDeep,
      child: const Center(
        child: Icon(Icons.eco_rounded, color: Colors.white54, size: 34),
      ),
    );
  }
}

/// Card vertical da Visão em Grade 2 colunas (fiel a "Plantas Coleções Conta 1.pdf").
class _CollectionPlantGridCard extends StatelessWidget {
  final PlantModel plant;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onMoreTap;

  const _CollectionPlantGridCard({
    required this.plant,
    required this.isDark,
    required this.onTap,
    required this.onBookmarkTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final locationText = plant.enderecoPrincipal.isNotEmpty
        ? plant.enderecoPrincipal
        : (plant.categoria.isNotEmpty ? plant.categoria : 'Santarém - PA, Amazônia');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? SumaColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem no topo com ícones Bookmark e ⋮ sobrepostos no canto superior direito
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    plant.imagemUrl.isNotEmpty
                        ? Image.network(
                            plant.imagemUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: SumaColors.greenDeep,
                              child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 36),
                            ),
                          )
                        : Container(
                            color: SumaColors.greenDeep,
                            child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 36),
                          ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.48),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onBookmarkTap,
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.bookmark_border_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onMoreTap,
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Textos e pílulas na parte inferior
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                    ),
                  ),
                  if (plant.nomeCientifico.isNotEmpty)
                    Text(
                      plant.nomeCientifico,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : const Color(0xFF333333),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _PlantFeaturePillsRow(plant: plant, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de pílulas verdes ("Áudio", "Modelo 3D", "•••") fiel aos PDFs.
class _PlantFeaturePillsRow extends StatelessWidget {
  final PlantModel plant;
  final bool compact;

  const _PlantFeaturePillsRow({
    required this.plant,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <_PillBadgeItem>[];
    if (plant.hasAudio) {
      labels.add(const _PillBadgeItem(icon: Icons.volume_up_outlined, label: 'Áudio'));
    }
    if (plant.hasModel3d) {
      labels.add(const _PillBadgeItem(icon: Icons.nature_outlined, label: 'Modelo 3D'));
    }
    if (labels.length < 2 && plant.hasCientifico) {
      labels.add(const _PillBadgeItem(icon: Icons.science_outlined, label: 'Científico'));
    }
    if (labels.isEmpty) {
      labels.add(const _PillBadgeItem(icon: Icons.volume_up_outlined, label: 'Áudio'));
      labels.add(const _PillBadgeItem(icon: Icons.nature_outlined, label: 'Modelo 3D'));
    }

    return Row(
      children: [
        ...labels.take(2).map(
          (item) => Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              padding: EdgeInsets.fromLTRB(3, 2, compact ? 6 : 8, 2),
              decoration: BoxDecoration(
                color: SumaColors.greenAccentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 16 : 18,
                    height: compact ? 16 : 18,
                    decoration: const BoxDecoration(
                      color: kAccountGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: compact ? 10 : 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: SumaColors.greenDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: compact ? 20 : 22,
          height: compact ? 18 : 20,
          decoration: BoxDecoration(
            color: kAccountGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _PillBadgeItem {
  final IconData icon;
  final String label;
  const _PillBadgeItem({required this.icon, required this.label});
}
