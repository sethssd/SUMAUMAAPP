import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../utils/app_theme.dart';

/// Estado imutável dos filtros selecionados no modal "Filtro de Pesquisa".
class PlantFilterState {
  /// Categorias selecionadas na seção "Tipo". Vazio significa "Todas".
  final Set<String> tipos;

  /// Opções selecionadas na seção "Utilidades" (Chá, Suco, Banho, Artesanato).
  final Set<String> utilidades;

  /// Opções selecionadas na seção "Partes da Planta" (Raiz, Caule, Semente, Fruto, Flor).
  final Set<String> partes;

  /// Opções selecionadas na seção "Outros"
  /// (Áudio, Modelo 3D, Artigos Científicos, Resumo, Pesquisa Científica, Visitação).
  final Set<String> outros;

  const PlantFilterState({
    this.tipos = const {},
    this.utilidades = const {},
    this.partes = const {},
    this.outros = const {},
  });

  bool get hasActiveFilters =>
      tipos.isNotEmpty ||
      utilidades.isNotEmpty ||
      partes.isNotEmpty ||
      outros.isNotEmpty;

  int get activeCount =>
      tipos.length + utilidades.length + partes.length + outros.length;

  PlantFilterState copyWith({
    Set<String>? tipos,
    Set<String>? utilidades,
    Set<String>? partes,
    Set<String>? outros,
  }) {
    return PlantFilterState(
      tipos: tipos ?? this.tipos,
      utilidades: utilidades ?? this.utilidades,
      partes: partes ?? this.partes,
      outros: outros ?? this.outros,
    );
  }

  /// Remove um filtro específico pelo seu identificador/rótulo.
  PlantFilterState removeFilter(String id) {
    return PlantFilterState(
      tipos: Set<String>.from(tipos)..remove(id),
      utilidades: Set<String>.from(utilidades)..remove(id),
      partes: Set<String>.from(partes)..remove(id),
      outros: Set<String>.from(outros)..remove(id),
    );
  }

  /// Retorna uma lista com todos os identificadores ativos.
  List<String> get activeLabels => [
        ...tipos,
        ...utilidades,
        ...partes,
        ...outros,
      ];

  static String _norm(String input) {
    const withDia = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const withoutDia = 'aaaaaeeeeiiiiooooouuuucn';
    var res = input.trim().toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      res = res.replaceAll(withDia[i], withoutDia[i]);
    }
    return res;
  }

  bool _plantMatchesTipo(PlantModel plant, String tipo) {
    final target = _norm(tipo);
    if (_norm(plant.categoria) == target ||
        _norm(plant.categoria).contains(target)) {
      return true;
    }
    if (plant.keywords.any((k) => _norm(k).contains(target))) return true;
    if (plant.aspectosUso.any((a) => _norm(a).contains(target))) return true;
    if (_norm(plant.usosEValorEconomico).contains(target)) return true;
    if (_norm(plant.resumoLimpo).contains(target)) return true;
    return false;
  }

  bool _plantMatchesUtilidade(PlantModel plant, String utilidade) {
    final target = _norm(utilidade);
    final terms = (target == 'artesanato' || target == 'artesenato')
        ? ['artesanato', 'artesenato', 'artesanal', 'cestaria', 'cuia', 'utensilio', 'madeira']
        : [target];

    for (final term in terms) {
      if (plant.aspectosUso.any((a) => _norm(a).contains(term))) return true;
      if (plant.keywords.any((k) => _norm(k).contains(term))) return true;
      if (plant.beneficios.any((b) => _norm(b).contains(term))) return true;
      if (_norm(plant.comoUsar).contains(term)) return true;
      if (_norm(plant.usosEValorEconomico).contains(term)) return true;
      if (_norm(plant.resumoLimpo).contains(term)) return true;
    }
    return false;
  }

  bool _plantMatchesParte(PlantModel plant, String parte) {
    final target = _norm(parte);
    final List<String> terms;
    switch (target) {
      case 'caule':
        terms = ['caule', 'casca', 'tronco', 'galho'];
        break;
      case 'raiz':
        terms = ['raiz', 'raizes', 'rizoma', 'tuberc'];
        break;
      case 'semente':
        terms = ['semente', 'amendoa', 'castanha', 'grao'];
        break;
      case 'fruto':
        terms = ['fruto', 'fruta', 'polpa', 'baga'];
        break;
      case 'flor':
        terms = ['flor', 'flores', 'inflorescencia', 'petala'];
        break;
      default:
        terms = [target];
    }

    for (final term in terms) {
      if (plant.aspectosUso.any((a) => _norm(a).contains(term))) return true;
      if (plant.keywords.any((k) => _norm(k).contains(term))) return true;
      if (_norm(plant.comoUsar).contains(term)) return true;
      if (_norm(plant.usosEValorEconomico).contains(term)) return true;
      if (_norm(plant.fenologia).contains(term)) return true;
      if (_norm(plant.resumoLimpo).contains(term)) return true;
    }
    return false;
  }

  bool _plantMatchesOutro(PlantModel plant, String outro) {
    final target = _norm(outro);
    if (target.contains('audio')) return plant.hasAudio;
    if (target.contains('3d')) return plant.hasModel3d;
    if (target.contains('artigos')) return plant.hasArticles;
    if (target.contains('resumo')) return plant.hasResumo;
    if (target.contains('pesquisa') || target.contains('cientifica')) {
      return plant.hasCientifico;
    }
    if (target.contains('visitacao')) return plant.hasVisitacao;
    return false;
  }

  /// Calcula quantos filtros ativos [plant] atende.
  int matchScore(PlantModel plant) {
    int score = 0;
    for (final t in tipos) {
      if (_plantMatchesTipo(plant, t)) score++;
    }
    for (final u in utilidades) {
      if (_plantMatchesUtilidade(plant, u)) score++;
    }
    for (final p in partes) {
      if (_plantMatchesParte(plant, p)) score++;
    }
    for (final o in outros) {
      if (_plantMatchesOutro(plant, o)) score++;
    }
    return score;
  }

  /// Verifica se [plant] atende aos filtros ativos.
  bool matchesPlant(PlantModel plant) {
    if (!hasActiveFilters) return true;
    return matchScore(plant) > 0;
  }
}

/// Abre o card flutuante "Filtro de Pesquisa" com animação orgânica.
Future<PlantFilterState?> showSearchFilterModal({
  required BuildContext context,
  required PlantFilterState initialState,
  ValueChanged<PlantFilterState>? onChanged,
}) {
  return showGeneralDialog<PlantFilterState>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar Filtro de Pesquisa',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, anim1, anim2) {
      return _SearchFilterDialog(
        initialState: initialState,
        onChanged: onChanged,
      );
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          alignment: const Alignment(0.85, -0.82),
          child: child,
        ),
      );
    },
  );
}

enum FilterIconType {
  todas,
  medicinais,
  frutiferas,
  aromaticas,
  madeireiras,
  ornamentais,
  alimenticias,
  toxicas,
  aquaticas,
  cha,
  suco,
  banho,
  artesanato,
  raiz,
  caule,
  semente,
  fruto,
  flor,
  audio,
  modelo3d,
  artigosCientificos,
  resumo,
  pesquisaCientifica,
  visitacao,
}

/// Retorna o tipo de ícone correspondente ao nome do filtro.
FilterIconType iconTypeForFilterLabel(String label) {
  final n = PlantFilterState._norm(label);
  if (n.contains('medic')) return FilterIconType.medicinais;
  if (n.contains('frutif')) return FilterIconType.frutiferas;
  if (n.contains('aromat')) return FilterIconType.aromaticas;
  if (n.contains('madeir')) return FilterIconType.madeireiras;
  if (n.contains('ornament')) return FilterIconType.ornamentais;
  if (n.contains('aliment')) return FilterIconType.alimenticias;
  if (n.contains('toxic')) return FilterIconType.toxicas;
  if (n.contains('aquat')) return FilterIconType.aquaticas;
  if (n.contains('cha')) return FilterIconType.cha;
  if (n.contains('suco')) return FilterIconType.suco;
  if (n.contains('banho')) return FilterIconType.banho;
  if (n.contains('artesan') || n.contains('artesen')) return FilterIconType.artesanato;
  if (n.contains('raiz')) return FilterIconType.raiz;
  if (n.contains('caule')) return FilterIconType.caule;
  if (n.contains('semente')) return FilterIconType.semente;
  if (n.contains('fruto')) return FilterIconType.fruto;
  if (n.contains('flor')) return FilterIconType.flor;
  if (n.contains('audio')) return FilterIconType.audio;
  if (n.contains('3d')) return FilterIconType.modelo3d;
  if (n.contains('artigo')) return FilterIconType.artigosCientificos;
  if (n.contains('resumo')) return FilterIconType.resumo;
  if (n.contains('pesquisa') || n.contains('cientif')) return FilterIconType.pesquisaCientifica;
  if (n.contains('visit')) return FilterIconType.visitacao;
  return FilterIconType.todas;
}

class _FilterOptionSpec {
  final String id;
  final String label;
  final FilterIconType iconType;

  const _FilterOptionSpec({
    required this.id,
    required this.label,
    required this.iconType,
  });
}

class _SearchFilterDialog extends StatefulWidget {
  final PlantFilterState initialState;
  final ValueChanged<PlantFilterState>? onChanged;

  const _SearchFilterDialog({
    required this.initialState,
    this.onChanged,
  });

  @override
  State<_SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<_SearchFilterDialog> {
  late Set<String> _tipos;
  late Set<String> _utilidades;
  late Set<String> _partes;
  late Set<String> _outros;

  bool _openTipo = true;
  bool _openUtilidades = true;
  bool _openPartes = true;
  bool _openOutros = true;

  // Contadores de geração para reexecutar a animação em cascata ao abrir cada seção
  int _genTipo = 0;
  int _genUtilidades = 0;
  int _genPartes = 0;
  int _genOutros = 0;

  static const List<_FilterOptionSpec> _tipoOptions = [
    _FilterOptionSpec(id: 'Todas', label: 'Todas', iconType: FilterIconType.todas),
    _FilterOptionSpec(id: 'Medicinais', label: 'Medicinais', iconType: FilterIconType.medicinais),
    _FilterOptionSpec(id: 'Frutíferas', label: 'Frutíferas', iconType: FilterIconType.frutiferas),
    _FilterOptionSpec(id: 'Aromáticas', label: 'Aromáticas', iconType: FilterIconType.aromaticas),
    _FilterOptionSpec(id: 'Madeireiras', label: 'Madeireiras', iconType: FilterIconType.madeireiras),
    _FilterOptionSpec(id: 'Ornamentais', label: 'Ornamentais', iconType: FilterIconType.ornamentais),
    _FilterOptionSpec(id: 'Alimentícias', label: 'Alimentícias', iconType: FilterIconType.alimenticias),
    _FilterOptionSpec(id: 'Tóxicas', label: 'Tóxicas', iconType: FilterIconType.toxicas),
    _FilterOptionSpec(id: 'Aquáticas', label: 'Aquáticas', iconType: FilterIconType.aquaticas),
  ];

  static const List<_FilterOptionSpec> _utilidadesOptions = [
    _FilterOptionSpec(id: 'Chá', label: 'Chá', iconType: FilterIconType.cha),
    _FilterOptionSpec(id: 'Suco', label: 'Suco', iconType: FilterIconType.suco),
    _FilterOptionSpec(id: 'Banho', label: 'Banho', iconType: FilterIconType.banho),
    _FilterOptionSpec(id: 'Artesanato', label: 'Artesanato', iconType: FilterIconType.artesanato),
  ];

  static const List<_FilterOptionSpec> _partesRow1 = [
    _FilterOptionSpec(id: 'Raiz', label: 'Raiz', iconType: FilterIconType.raiz),
    _FilterOptionSpec(id: 'Caule', label: 'Caule', iconType: FilterIconType.caule),
    _FilterOptionSpec(id: 'Semente', label: 'Semente', iconType: FilterIconType.semente),
  ];

  static const List<_FilterOptionSpec> _partesRow2 = [
    _FilterOptionSpec(id: 'Fruto', label: 'Fruto', iconType: FilterIconType.fruto),
    _FilterOptionSpec(id: 'Flor', label: 'Flor', iconType: FilterIconType.flor),
  ];

  static const List<_FilterOptionSpec> _outrosOptions = [
    _FilterOptionSpec(id: 'Áudio', label: 'Áudio', iconType: FilterIconType.audio),
    _FilterOptionSpec(id: 'Modelo 3D', label: 'Modelo 3D', iconType: FilterIconType.modelo3d),
    _FilterOptionSpec(
      id: 'Artigos Científicos',
      label: 'Artigos Científicos',
      iconType: FilterIconType.artigosCientificos,
    ),
    _FilterOptionSpec(id: 'Resumo', label: 'Resumo', iconType: FilterIconType.resumo),
    _FilterOptionSpec(
      id: 'Pesquisa Científica',
      label: 'Pesquisa Científica',
      iconType: FilterIconType.pesquisaCientifica,
    ),
    _FilterOptionSpec(id: 'Visitação', label: 'Visitação', iconType: FilterIconType.visitacao),
  ];

  @override
  void initState() {
    super.initState();
    _tipos = Set<String>.from(widget.initialState.tipos);
    _utilidades = Set<String>.from(widget.initialState.utilidades);
    _partes = Set<String>.from(widget.initialState.partes);
    _outros = Set<String>.from(widget.initialState.outros);
  }

  PlantFilterState _buildCurrentState() {
    return PlantFilterState(
      tipos: Set<String>.from(_tipos),
      utilidades: Set<String>.from(_utilidades),
      partes: Set<String>.from(_partes),
      outros: Set<String>.from(_outros),
    );
  }

  void _notifyStateChanged() {
    widget.onChanged?.call(_buildCurrentState());
  }

  void _toggleTipo(String id) {
    setState(() {
      if (id == 'Todas') {
        _tipos.clear();
      } else {
        if (_tipos.contains(id)) {
          _tipos.remove(id);
        } else {
          _tipos.add(id);
        }
      }
    });
    _notifyStateChanged();
  }

  void _toggleInSet(Set<String> targetSet, String id) {
    setState(() {
      if (targetSet.contains(id)) {
        targetSet.remove(id);
      } else {
        targetSet.add(id);
      }
    });
    _notifyStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            math.max(16, media.size.height * 0.025),
            24,
            20,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: media.size.height * 0.87,
              ),
              decoration: BoxDecoration(
                color: isDark ? SumaColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF7AB66E).withValues(alpha: isDark ? 0.28 : 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.60 : 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Cabeçalho: "Filtro de Pesquisa" + Limpar + botão X ─────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtro de Pesquisa',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (_buildCurrentState().hasActiveFilters)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _tipos.clear();
                                  _utilidades.clear();
                                  _partes.clear();
                                  _outros.clear();
                                });
                                _notifyStateChanged();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Limpar',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7AB66E),
                                ),
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(_buildCurrentState()),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 28,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Corpo rolável com as 4 seções em cascata elástica ──────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          // Largura responsiva para 3 colunas e 4 colunas sem cortar palavras
                          final width3Col = ((maxW - 24) / 3).clamp(84.0, 104.0);
                          final width4Col = ((maxW - 27) / 4).clamp(68.0, 82.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Seção: Tipo
                              _FilterSectionHeader(
                                title: 'Tipo',
                                count: _tipos.length,
                                isOpen: _openTipo,
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _openTipo = !_openTipo;
                                  if (_openTipo) _genTipo++;
                                }),
                              ),
                              _CollapsibleFilterBody(
                                isOpen: _openTipo,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  child: Center(
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 14,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (int i = 0; i < _tipoOptions.length; i++)
                                          _StaggeredEntrance(
                                            key: ValueKey('tipo_${_genTipo}_$i'),
                                            index: i,
                                            child: _AnimatedFilterTile(
                                              spec: _tipoOptions[i],
                                              isSelected: _tipoOptions[i].id == 'Todas'
                                                  ? _tipos.isEmpty
                                                  : _tipos.contains(_tipoOptions[i].id),
                                              width: width3Col,
                                              height: 76,
                                              onTap: () => _toggleTipo(_tipoOptions[i].id),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Seção: Utilidades
                              _FilterSectionHeader(
                                title: 'Utilidades',
                                count: _utilidades.length,
                                isOpen: _openUtilidades,
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _openUtilidades = !_openUtilidades;
                                  if (_openUtilidades) _genUtilidades++;
                                }),
                              ),
                              _CollapsibleFilterBody(
                                isOpen: _openUtilidades,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 18),
                                  child: Center(
                                    child: Wrap(
                                      spacing: 9,
                                      runSpacing: 14,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (int i = 0; i < _utilidadesOptions.length; i++)
                                          _StaggeredEntrance(
                                            key: ValueKey('util_${_genUtilidades}_$i'),
                                            index: i,
                                            child: _AnimatedFilterTile(
                                              spec: _utilidadesOptions[i],
                                              isSelected: _utilidades.contains(_utilidadesOptions[i].id),
                                              width: width4Col,
                                              height: 74,
                                              onTap: () => _toggleInSet(_utilidades, _utilidadesOptions[i].id),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 3. Seção: Partes da Planta
                              _FilterSectionHeader(
                                title: 'Partes da Planta',
                                count: _partes.length,
                                isOpen: _openPartes,
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _openPartes = !_openPartes;
                                  if (_openPartes) _genPartes++;
                                }),
                              ),
                              _CollapsibleFilterBody(
                                isOpen: _openPartes,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 18),
                                  child: Column(
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 14,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          for (int i = 0; i < _partesRow1.length; i++)
                                            _StaggeredEntrance(
                                              key: ValueKey('partes1_${_genPartes}_$i'),
                                              index: i,
                                              child: _AnimatedFilterTile(
                                                spec: _partesRow1[i],
                                                isSelected: _partes.contains(_partesRow1[i].id),
                                                width: width3Col,
                                                height: 74,
                                                onTap: () => _toggleInSet(_partes, _partesRow1[i].id),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 14,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          for (int i = 0; i < _partesRow2.length; i++)
                                            _StaggeredEntrance(
                                              key: ValueKey('partes2_${_genPartes}_$i'),
                                              index: i + 3,
                                              child: _AnimatedFilterTile(
                                                spec: _partesRow2[i],
                                                isSelected: _partes.contains(_partesRow2[i].id),
                                                width: width3Col,
                                                height: 74,
                                                onTap: () => _toggleInSet(_partes, _partesRow2[i].id),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 4. Seção: Outros
                              _FilterSectionHeader(
                                title: 'Outros',
                                count: _outros.length,
                                isOpen: _openOutros,
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _openOutros = !_openOutros;
                                  if (_openOutros) _genOutros++;
                                }),
                              ),
                              _CollapsibleFilterBody(
                                isOpen: _openOutros,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                                  child: Center(
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 14,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (int i = 0; i < _outrosOptions.length; i++)
                                          _StaggeredEntrance(
                                            key: ValueKey('outros_${_genOutros}_$i'),
                                            index: i,
                                            child: _AnimatedFilterTile(
                                              spec: _outrosOptions[i],
                                              isSelected: _outros.contains(_outrosOptions[i].id),
                                              width: width3Col,
                                              height: 76,
                                              onTap: () => _toggleInSet(_outros, _outrosOptions[i].id),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Anima o colapso/expansão suave de cada seção com curva orgânica.
class _CollapsibleFilterBody extends StatelessWidget {
  final bool isOpen;
  final Widget child;

  const _CollapsibleFilterBody({
    required this.isOpen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: isOpen
          ? child
          : const SizedBox(width: double.infinity, height: 6),
    );
  }
}

/// Entrada em cascata elástica (desabrochar sequencial) para cada botão da seção.
class _StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 28 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Cabeçalho colapsável de cada seção ("Tipo v", "Utilidades v", etc.)
class _FilterSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isOpen;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterSectionHeader({
    required this.title,
    required this.count,
    required this.isOpen,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF7A7A7A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF7AB66E).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7AB66E),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 3),
            AnimatedRotation(
              turns: isOpen ? 0.0 : -0.25,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão individual de filtro:
/// - Desativado: ícone verde, fundo branco com borda verde na parte superior,
///   e nome em branco com fundo verde na faixa inferior.
/// - Ativado: animação de movimento para cima e preenchimento verde em onda
///   subindo da faixa inferior até completar todo o botão (sem nenhuma linha branca interna).
/// - Rótulo: quando o texto não cabe na largura da caixa, desliza suavemente
///   indo e vindo (marquee contínuo) sem cortar nenhuma letra.
class _AnimatedFilterTile extends StatelessWidget {
  final _FilterOptionSpec spec;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _AnimatedFilterTile({
    required this.spec,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.onTap,
  });

  static const Color _kFilterGreen = Color(0xFF7AB66E);

  @override
  Widget build(BuildContext context) {
    const double labelAreaHeight = 22.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isSelected ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final double progress = t.clamp(0.0, 1.0);
          final double liftOffset = -4.5 * progress;

          return Transform.translate(
            offset: Offset(0, liftOffset),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: _kFilterGreen,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: _kFilterGreen,
                  width: 1.6,
                ),
                boxShadow: [
                  if (progress > 0.05)
                    BoxShadow(
                      color: _kFilterGreen.withValues(alpha: 0.38 * progress),
                      blurRadius: 10 * progress,
                      offset: Offset(0, 4 * progress),
                    ),
                ],
              ),
              child: Column(
                children: [
                  // ── Parte superior: fundo branco com ícone verde (desativado)
                  //    e onda verde subindo da base até completar o botão (ativado) ──
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Camada base (Ativado): usa o próprio verde contínuo do botão
                        //    sem nenhuma borda interna, com o ícone branco
                        Center(
                          child: Transform.translate(
                            offset: Offset(0, -1.5 * progress),
                            child: CustomPaint(
                              size: const Size(36, 36),
                              painter: FilterIconPainter(
                                type: spec.iconType,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // 2. Camada superior (Desativado): caixa branca com ícone verde,
                        //    recortada de baixo para cima em formato de onda suave conforme
                        //    o verde sobe (progress 0 -> 1). Quando progress == 1.0, não é
                        //    renderizada para garantir zero linha branca interna.
                        if (progress < 1.0)
                          ClipPath(
                            clipper: _WaveTopRemainingClipper(
                              progress: progress,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.5),
                              ),
                              child: Center(
                                child: Transform.translate(
                                  offset: Offset(0, -1.5 * progress),
                                  child: CustomPaint(
                                    size: const Size(36, 36),
                                    painter: FilterIconPainter(
                                      type: spec.iconType,
                                      color: _kFilterGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Faixa inferior: nome com fundo verde e efeito "indo e vindo"
                  //    automático caso o texto ultrapasse a largura da caixa ──
                  SizedBox(
                    height: labelAreaHeight,
                    width: double.infinity,
                    child: _MarqueeFilterLabel(
                      text: spec.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.8,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rótulo inteligente para a base do botão de filtro:
/// - Se o texto couber na largura da caixa, permanece centralizado e parado.
/// - Se for maior que a largura delimitada, desliza suavemente indo e vindo
///   (vai-e-vem horizontal contínuo) para que a pessoa leia tudo sem cortar.
class _MarqueeFilterLabel extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeFilterLabel({
    required this.text,
    required this.style,
  });

  @override
  State<_MarqueeFilterLabel> createState() => _MarqueeFilterLabelState();
}

class _MarqueeFilterLabelState extends State<_MarqueeFilterLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Pausa suave nas duas extremidades antes de inverter a direção ("indo e vindo")
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.84, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final singleLineText = widget.text.replaceAll('\n', ' ').trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(0.0, constraints.maxWidth - 8.0);
        final painter = TextPainter(
          text: TextSpan(text: singleLineText, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();

        final textWidth = painter.width;

        // Se couber perfeitamente na caixa, exibe centralizado sem animar
        if (textWidth <= availableWidth) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                singleLineText,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: widget.style,
              ),
            ),
          );
        }

        // Se ultrapassar a área delimitada, anima indo e vindo horizontalmente
        final double overflowDistance = textWidth - availableWidth + 6.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _curvedAnimation,
                builder: (context, child) {
                  final dx = -overflowDistance * _curvedAnimation.value;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: SizedBox(
                  width: textWidth + 4.0,
                  child: Text(
                    singleLineText,
                    maxLines: 1,
                    softWrap: false,
                    style: widget.style,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Recorta a área branca superior com uma crista de onda suave conforme o verde sobe da base.
class _WaveTopRemainingClipper extends CustomClipper<Path> {
  final double progress;

  const _WaveTopRemainingClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0.0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    if (p >= 1.0) {
      return Path();
    }

    final baseLineY = size.height * (1.0 - p);
    // Amplitude da onda é máxima no meio da subida e zera no início e no fim
    final waveAmp = 5.5 * math.sin(p * math.pi);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, (baseLineY + waveAmp * 0.4).clamp(0.0, size.height))
      ..quadraticBezierTo(
        size.width * 0.72,
        (baseLineY - waveAmp).clamp(0.0, size.height),
        size.width * 0.50,
        baseLineY.clamp(0.0, size.height),
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        (baseLineY + waveAmp).clamp(0.0, size.height),
        0,
        (baseLineY - waveAmp * 0.4).clamp(0.0, size.height),
      )
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _WaveTopRemainingClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

/// Desenha os ícones botânicos e científicos idênticos ao protótipo do Filtro de Pesquisa.
class FilterIconPainter extends CustomPainter {
  final FilterIconType type;
  final Color color;

  const FilterIconPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (type) {
      case FilterIconType.todas:
        const double r = 2.8;
        final xs = [w * 0.25, w * 0.50, w * 0.75];
        final ys = [h * 0.25, h * 0.50, h * 0.75];
        for (final x in xs) {
          for (final y in ys) {
            canvas.drawCircle(Offset(x, y), r, fillPaint);
          }
        }
        break;

      case FilterIconType.medicinais:
        canvas.drawLine(
          Offset(w * 0.45, h * 0.34),
          Offset(w * 0.60, h * 0.12),
          strokePaint..strokeWidth = 2.6,
        );
        final bowl = Path()
          ..moveTo(w * 0.20, h * 0.34)
          ..lineTo(w * 0.80, h * 0.34)
          ..lineTo(w * 0.70, h * 0.78)
          ..quadraticBezierTo(w * 0.50, h * 0.86, w * 0.30, h * 0.78)
          ..close();
        canvas.drawPath(bowl, strokePaint..strokeWidth = 2.3);
        canvas.drawLine(
          Offset(w * 0.28, h * 0.86),
          Offset(w * 0.72, h * 0.86),
          strokePaint,
        );
        canvas.drawLine(
          Offset(w * 0.50, h * 0.46),
          Offset(w * 0.50, h * 0.68),
          strokePaint..strokeWidth = 2.0,
        );
        canvas.drawLine(
          Offset(w * 0.39, h * 0.57),
          Offset(w * 0.61, h * 0.57),
          strokePaint..strokeWidth = 2.0,
        );
        break;

      case FilterIconType.frutiferas:
        final cupRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.18, h * 0.20, w * 0.50, h * 0.52),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        );
        canvas.drawRRect(cupRect, strokePaint);
        final handlePath = Path()
          ..moveTo(w * 0.68, h * 0.26)
          ..lineTo(w * 0.80, h * 0.26)
          ..quadraticBezierTo(w * 0.86, h * 0.26, w * 0.86, h * 0.38)
          ..quadraticBezierTo(w * 0.86, h * 0.50, w * 0.76, h * 0.50)
          ..lineTo(w * 0.68, h * 0.50);
        canvas.drawPath(handlePath, strokePaint);
        canvas.drawLine(Offset(w * 0.43, h * 0.20), Offset(w * 0.43, h * 0.34), strokePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.35, h * 0.34, w * 0.16, h * 0.20),
            const Radius.circular(2),
          ),
          fillPaint,
        );
        canvas.drawLine(Offset(w * 0.16, h * 0.84), Offset(w * 0.76, h * 0.84), strokePaint);
        break;

      case FilterIconType.aromaticas:
        final centerLeaf = Path()
          ..moveTo(w * 0.50, h * 0.16)
          ..quadraticBezierTo(w * 0.68, h * 0.45, w * 0.50, h * 0.82)
          ..quadraticBezierTo(w * 0.32, h * 0.45, w * 0.50, h * 0.16);
        canvas.drawPath(centerLeaf, strokePaint);

        final leftLeaf = Path()
          ..moveTo(w * 0.50, h * 0.82)
          ..quadraticBezierTo(w * 0.16, h * 0.76, w * 0.14, h * 0.40)
          ..quadraticBezierTo(w * 0.36, h * 0.44, w * 0.44, h * 0.68);
        canvas.drawPath(leftLeaf, strokePaint);

        final rightLeaf = Path()
          ..moveTo(w * 0.50, h * 0.82)
          ..quadraticBezierTo(w * 0.84, h * 0.76, w * 0.86, h * 0.40)
          ..quadraticBezierTo(w * 0.64, h * 0.44, w * 0.56, h * 0.68);
        canvas.drawPath(rightLeaf, strokePaint);
        break;

      case FilterIconType.madeireiras:
        void drawPine(double cx, double topY, double botY, double halfW) {
          final midY = topY + (botY - topY) * 0.44;
          final tree = Path()
            ..moveTo(cx, topY)
            ..lineTo(cx - halfW * 0.78, midY)
            ..lineTo(cx - halfW * 0.35, midY)
            ..lineTo(cx - halfW, botY - 6)
            ..lineTo(cx + halfW, botY - 6)
            ..lineTo(cx + halfW * 0.35, midY)
            ..lineTo(cx + halfW * 0.78, midY)
            ..close();
          canvas.drawPath(tree, strokePaint..strokeWidth = 2.0);
          canvas.drawLine(
            Offset(cx, botY - 6),
            Offset(cx, botY + 2),
            strokePaint..strokeWidth = 2.2,
          );
        }
        drawPine(w * 0.38, h * 0.12, h * 0.86, w * 0.22);
        drawPine(w * 0.64, h * 0.20, h * 0.86, w * 0.18);
        break;

      case FilterIconType.ornamentais:
        final center = Offset(w * 0.50, h * 0.36);
        canvas.drawCircle(center, 3.2, strokePaint..strokeWidth = 2.0);
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final petalCenter = Offset(
            center.dx + math.cos(angle) * 7.2,
            center.dy + math.sin(angle) * 7.2,
          );
          canvas.drawCircle(petalCenter, 4.2, strokePaint..strokeWidth = 2.0);
        }
        canvas.drawLine(
          Offset(w * 0.50, h * 0.54),
          Offset(w * 0.50, h * 0.88),
          strokePaint..strokeWidth = 2.2,
        );
        final baseLeaves = Path()
          ..moveTo(w * 0.50, h * 0.88)
          ..quadraticBezierTo(w * 0.20, h * 0.82, w * 0.22, h * 0.62)
          ..quadraticBezierTo(w * 0.44, h * 0.66, w * 0.50, h * 0.88)
          ..moveTo(w * 0.50, h * 0.88)
          ..quadraticBezierTo(w * 0.80, h * 0.82, w * 0.78, h * 0.62)
          ..quadraticBezierTo(w * 0.56, h * 0.66, w * 0.50, h * 0.88);
        canvas.drawPath(baseLeaves, strokePaint..strokeWidth = 2.0);
        break;

      case FilterIconType.alimenticias:
        for (final cx in [w * 0.33, w * 0.67]) {
          canvas.drawLine(
            Offset(cx, h * 0.08),
            Offset(cx, h * 0.15),
            strokePaint..strokeWidth = 2.4,
          );
          canvas.drawCircle(
            Offset(cx, h * 0.24),
            4.8,
            strokePaint..strokeWidth = 2.4,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, h * 0.40), width: 11.5, height: 4.5),
              const Radius.circular(2),
            ),
            fillPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, h * 0.52), width: 11.5, height: 4.5),
              const Radius.circular(2),
            ),
            fillPaint,
          );
          canvas.drawCircle(
            Offset(cx, h * 0.68),
            4.8,
            strokePaint..strokeWidth = 2.4,
          );
          canvas.drawLine(
            Offset(cx, h * 0.76),
            Offset(cx, h * 0.92),
            strokePaint..strokeWidth = 2.5,
          );
        }
        break;

      case FilterIconType.toxicas:
        final tri = Path()
          ..moveTo(w * 0.50, h * 0.14)
          ..lineTo(w * 0.86, h * 0.82)
          ..lineTo(w * 0.14, h * 0.82)
          ..close();
        canvas.drawPath(tri, strokePaint..strokeWidth = 2.5);
        canvas.drawLine(
          Offset(w * 0.50, h * 0.38),
          Offset(w * 0.50, h * 0.60),
          strokePaint..strokeWidth = 2.5,
        );
        canvas.drawCircle(Offset(w * 0.50, h * 0.71), 1.8, fillPaint);
        break;

      case FilterIconType.aquaticas:
        for (final y in [h * 0.32, h * 0.50, h * 0.68]) {
          final wave = Path()
            ..moveTo(w * 0.14, y)
            ..quadraticBezierTo(w * 0.23, y - 5, w * 0.32, y)
            ..quadraticBezierTo(w * 0.41, y + 5, w * 0.50, y)
            ..quadraticBezierTo(w * 0.59, y - 5, w * 0.68, y)
            ..quadraticBezierTo(w * 0.77, y + 5, w * 0.86, y);
          canvas.drawPath(wave, strokePaint..strokeWidth = 2.3);
        }
        break;

      case FilterIconType.cha:
        for (final sx in [w * 0.34, w * 0.46, w * 0.58]) {
          final steam = Path()
            ..moveTo(sx, h * 0.30)
            ..quadraticBezierTo(sx + 2.5, h * 0.22, sx - 1.5, h * 0.12);
          canvas.drawPath(steam, strokePaint..strokeWidth = 1.9);
        }
        final teaCup = Path()
          ..moveTo(w * 0.20, h * 0.42)
          ..lineTo(w * 0.72, h * 0.42)
          ..quadraticBezierTo(w * 0.70, h * 0.74, w * 0.46, h * 0.74)
          ..quadraticBezierTo(w * 0.22, h * 0.74, w * 0.20, h * 0.42)
          ..close();
        canvas.drawPath(teaCup, strokePaint..strokeWidth = 2.2);
        final teaHandle = Path()
          ..moveTo(w * 0.71, h * 0.46)
          ..quadraticBezierTo(w * 0.86, h * 0.46, w * 0.85, h * 0.57)
          ..quadraticBezierTo(w * 0.84, h * 0.67, w * 0.66, h * 0.66);
        canvas.drawPath(teaHandle, strokePaint..strokeWidth = 2.1);
        canvas.drawLine(
          Offset(w * 0.14, h * 0.82),
          Offset(w * 0.82, h * 0.82),
          strokePaint..strokeWidth = 2.3,
        );
        break;

      case FilterIconType.suco:
        final glass = Path()
          ..moveTo(w * 0.34, h * 0.36)
          ..lineTo(w * 0.68, h * 0.36)
          ..lineTo(w * 0.63, h * 0.86)
          ..lineTo(w * 0.39, h * 0.86)
          ..close();
        canvas.drawPath(glass, strokePaint..strokeWidth = 2.1);
        canvas.drawLine(
          Offset(w * 0.36, h * 0.50),
          Offset(w * 0.66, h * 0.50),
          strokePaint..strokeWidth = 1.8,
        );
        final straw = Path()
          ..moveTo(w * 0.52, h * 0.76)
          ..lineTo(w * 0.58, h * 0.14)
          ..lineTo(w * 0.72, h * 0.18);
        canvas.drawPath(straw, strokePaint..strokeWidth = 2.0);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.34, h * 0.34), radius: 6.5),
          math.pi * 0.65,
          math.pi * 1.25,
          false,
          strokePaint..strokeWidth = 2.0,
        );
        break;

      case FilterIconType.banho:
        final pipe = Path()
          ..moveTo(w * 0.14, h * 0.38)
          ..lineTo(w * 0.14, h * 0.22)
          ..quadraticBezierTo(w * 0.14, h * 0.14, w * 0.24, h * 0.14)
          ..lineTo(w * 0.48, h * 0.14)
          ..quadraticBezierTo(w * 0.58, h * 0.14, w * 0.58, h * 0.26);
        canvas.drawPath(pipe, strokePaint..strokeWidth = 2.3);
        final head = Path()
          ..moveTo(w * 0.36, h * 0.42)
          ..quadraticBezierTo(w * 0.58, h * 0.24, w * 0.80, h * 0.42)
          ..close();
        canvas.drawPath(head, strokePaint..strokeWidth = 2.2);
        for (final dx in [w * 0.42, w * 0.52, w * 0.62, w * 0.72]) {
          canvas.drawLine(
            Offset(dx, h * 0.54),
            Offset(dx, h * 0.62),
            strokePaint..strokeWidth = 2.0,
          );
          canvas.drawLine(
            Offset(dx, h * 0.72),
            Offset(dx, h * 0.82),
            strokePaint..strokeWidth = 2.0,
          );
        }
        break;

      case FilterIconType.artesanato:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.50, h * 0.60), width: w * 0.80, height: h * 0.34),
          strokePaint..strokeWidth = 2.2,
        );
        final crown = Path()
          ..moveTo(w * 0.27, h * 0.56)
          ..quadraticBezierTo(w * 0.28, h * 0.26, w * 0.50, h * 0.26)
          ..quadraticBezierTo(w * 0.72, h * 0.26, w * 0.73, h * 0.56);
        canvas.drawPath(crown, strokePaint..strokeWidth = 2.2);
        final band = Path()
          ..moveTo(w * 0.27, h * 0.55)
          ..quadraticBezierTo(w * 0.50, h * 0.63, w * 0.73, h * 0.55);
        canvas.drawPath(band, strokePaint..strokeWidth = 2.0);
        break;

      case FilterIconType.raiz:
        canvas.drawLine(
          Offset(w * 0.50, h * 0.14),
          Offset(w * 0.50, h * 0.78),
          strokePaint..strokeWidth = 2.4,
        );
        final roots = Path()
          ..moveTo(w * 0.50, h * 0.34)
          ..quadraticBezierTo(w * 0.30, h * 0.44, w * 0.14, h * 0.66)
          ..moveTo(w * 0.32, h * 0.48)
          ..lineTo(w * 0.26, h * 0.74)
          ..moveTo(w * 0.38, h * 0.42)
          ..lineTo(w * 0.42, h * 0.62)
          ..moveTo(w * 0.50, h * 0.36)
          ..quadraticBezierTo(w * 0.70, h * 0.46, w * 0.86, h * 0.68)
          ..moveTo(w * 0.68, h * 0.50)
          ..lineTo(w * 0.74, h * 0.76)
          ..moveTo(w * 0.60, h * 0.44)
          ..lineTo(w * 0.58, h * 0.64);
        canvas.drawPath(roots, strokePaint..strokeWidth = 2.1);
        break;

      case FilterIconType.caule:
        final mainStem = Path()
          ..moveTo(w * 0.24, h * 0.14)
          ..quadraticBezierTo(w * 0.44, h * 0.54, w * 0.80, h * 0.78);
        canvas.drawPath(mainStem, strokePaint..strokeWidth = 2.8);

        final sideBranches = Path()
          ..moveTo(w * 0.42, h * 0.44)
          ..quadraticBezierTo(w * 0.60, h * 0.36, w * 0.66, h * 0.18)
          ..moveTo(w * 0.52, h * 0.56)
          ..quadraticBezierTo(w * 0.38, h * 0.72, w * 0.18, h * 0.74)
          ..moveTo(w * 0.66, h * 0.68)
          ..lineTo(w * 0.82, h * 0.58);
        canvas.drawPath(sideBranches, strokePaint..strokeWidth = 2.1);
        break;

      case FilterIconType.semente:
        final seedOuter = Path()
          ..moveTo(w * 0.50, h * 0.12)
          ..quadraticBezierTo(w * 0.86, h * 0.36, w * 0.54, h * 0.88)
          ..quadraticBezierTo(w * 0.14, h * 0.46, w * 0.50, h * 0.12);
        canvas.drawPath(seedOuter, strokePaint..strokeWidth = 2.0);
        final midLine = Path()
          ..moveTo(w * 0.50, h * 0.12)
          ..quadraticBezierTo(w * 0.42, h * 0.50, w * 0.54, h * 0.88);
        canvas.drawPath(midLine, strokePaint..strokeWidth = 1.9);
        canvas.drawLine(Offset(w * 0.48, h * 0.36), Offset(w * 0.67, h * 0.28), strokePaint..strokeWidth = 1.6);
        canvas.drawLine(Offset(w * 0.47, h * 0.52), Offset(w * 0.70, h * 0.44), strokePaint..strokeWidth = 1.6);
        canvas.drawLine(Offset(w * 0.49, h * 0.68), Offset(w * 0.68, h * 0.60), strokePaint..strokeWidth = 1.6);
        break;

      case FilterIconType.fruto:
        canvas.drawCircle(
          Offset(w * 0.50, h * 0.58),
          w * 0.27,
          strokePaint..strokeWidth = 2.3,
        );
        final stem = Path()
          ..moveTo(w * 0.48, h * 0.31)
          ..quadraticBezierTo(w * 0.42, h * 0.18, w * 0.34, h * 0.16);
        canvas.drawPath(stem, strokePaint..strokeWidth = 2.1);
        final fruitLeaf = Path()
          ..moveTo(w * 0.50, h * 0.30)
          ..quadraticBezierTo(w * 0.56, h * 0.12, w * 0.72, h * 0.18)
          ..quadraticBezierTo(w * 0.64, h * 0.32, w * 0.50, h * 0.30);
        canvas.drawPath(fruitLeaf, strokePaint..strokeWidth = 2.0);
        break;

      case FilterIconType.flor:
        final c = Offset(w * 0.50, h * 0.50);
        canvas.drawCircle(c, 3.8, strokePaint..strokeWidth = 1.9);
        for (int i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * (2 * math.pi / 5);
          final px = c.dx + math.cos(a) * 9.5;
          final py = c.dy + math.sin(a) * 9.5;
          canvas.drawCircle(Offset(px, py), 5.6, strokePaint..strokeWidth = 2.0);
        }
        break;

      case FilterIconType.audio:
        final speaker = Path()
          ..moveTo(w * 0.14, h * 0.40)
          ..lineTo(w * 0.28, h * 0.40)
          ..lineTo(w * 0.48, h * 0.20)
          ..lineTo(w * 0.48, h * 0.80)
          ..lineTo(w * 0.28, h * 0.60)
          ..lineTo(w * 0.14, h * 0.60)
          ..close();
        canvas.drawPath(speaker, strokePaint..strokeWidth = 2.2);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.50, h * 0.50), radius: w * 0.18),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          strokePaint..strokeWidth = 2.2,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.50, h * 0.50), radius: w * 0.31),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          strokePaint..strokeWidth = 2.2,
        );
        break;

      case FilterIconType.modelo3d:
        final cx = w * 0.50;
        final cy = h * 0.50;
        const r = 10.0;
        final topPt = Offset(cx, cy - r);
        final botPt = Offset(cx, cy + r);
        final leftTop = Offset(cx - r * 0.88, cy - r * 0.48);
        final rightTop = Offset(cx + r * 0.88, cy - r * 0.48);
        final leftBot = Offset(cx - r * 0.88, cy + r * 0.48);
        final rightBot = Offset(cx + r * 0.88, cy + r * 0.48);

        final hex = Path()
          ..moveTo(topPt.dx, topPt.dy)
          ..lineTo(rightTop.dx, rightTop.dy)
          ..lineTo(rightBot.dx, rightBot.dy)
          ..lineTo(botPt.dx, botPt.dy)
          ..lineTo(leftBot.dx, leftBot.dy)
          ..lineTo(leftTop.dx, leftTop.dy)
          ..close();
        canvas.drawPath(hex, strokePaint..strokeWidth = 2.0);
        canvas.drawLine(Offset(cx, cy), leftTop, strokePaint..strokeWidth = 1.9);
        canvas.drawLine(Offset(cx, cy), rightTop, strokePaint..strokeWidth = 1.9);
        canvas.drawLine(Offset(cx, cy), botPt, strokePaint..strokeWidth = 1.9);

        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: w * 0.78, height: h * 0.78),
          -math.pi * 0.78,
          math.pi * 0.52,
          false,
          strokePaint..strokeWidth = 1.9,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: w * 0.78, height: h * 0.78),
          math.pi * 0.22,
          math.pi * 0.52,
          false,
          strokePaint..strokeWidth = 1.9,
        );
        break;

      case FilterIconType.artigosCientificos:
      case FilterIconType.resumo:
        final doc = Path()
          ..moveTo(w * 0.24, h * 0.14)
          ..lineTo(w * 0.62, h * 0.14)
          ..lineTo(w * 0.76, h * 0.28)
          ..lineTo(w * 0.76, h * 0.86)
          ..lineTo(w * 0.24, h * 0.86)
          ..close();
        canvas.drawPath(doc, strokePaint..strokeWidth = 2.1);
        final fold = Path()
          ..moveTo(w * 0.60, h * 0.14)
          ..lineTo(w * 0.60, h * 0.30)
          ..lineTo(w * 0.76, h * 0.30);
        canvas.drawPath(fold, strokePaint..strokeWidth = 1.9);
        for (final ly in [h * 0.44, h * 0.58, h * 0.72]) {
          canvas.drawLine(
            Offset(w * 0.34, ly),
            Offset(w * 0.66, ly),
            strokePaint..strokeWidth = 2.0,
          );
        }
        break;

      case FilterIconType.pesquisaCientifica:
        canvas.drawLine(
          Offset(w * 0.58, h * 0.14),
          Offset(w * 0.38, h * 0.44),
          strokePaint..strokeWidth = 3.2,
        );
        final arm = Path()
          ..moveTo(w * 0.48, h * 0.28)
          ..quadraticBezierTo(w * 0.78, h * 0.40, w * 0.62, h * 0.74);
        canvas.drawPath(arm, strokePaint..strokeWidth = 2.6);
        canvas.drawLine(
          Offset(w * 0.26, h * 0.58),
          Offset(w * 0.56, h * 0.58),
          strokePaint..strokeWidth = 2.3,
        );
        canvas.drawLine(
          Offset(w * 0.20, h * 0.84),
          Offset(w * 0.78, h * 0.84),
          strokePaint..strokeWidth = 2.8,
        );
        canvas.drawLine(
          Offset(w * 0.48, h * 0.74),
          Offset(w * 0.48, h * 0.84),
          strokePaint..strokeWidth = 2.6,
        );
        break;

      case FilterIconType.visitacao:
        final pin = Path()
          ..moveTo(w * 0.50, h * 0.88)
          ..quadraticBezierTo(w * 0.20, h * 0.56, w * 0.20, h * 0.38)
          ..arcToPoint(
            Offset(w * 0.80, h * 0.38),
            radius: Radius.circular(w * 0.30),
            clockwise: true,
          )
          ..quadraticBezierTo(w * 0.80, h * 0.56, w * 0.50, h * 0.88)
          ..close();
        canvas.drawPath(pin, strokePaint..strokeWidth = 2.3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(w * 0.50, h * 0.39), width: w * 0.32, height: h * 0.22),
            const Radius.circular(3),
          ),
          strokePaint..strokeWidth = 1.9,
        );
        canvas.drawCircle(Offset(w * 0.50, h * 0.39), 3.0, fillPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant FilterIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
