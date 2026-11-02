import 'package:flutter/material.dart';
import '../services/account_library_service.dart';
import '../utils/app_theme.dart';
import '../widgets/account/botanical_header.dart';
import 'collection_plants_screen.dart';

enum _CollectionSort {
  dataCriacao,
  alfabetica,
  quantidadeItens,
}

/// Tela de Coleções do usuário — fiel a "Coleções Conta.pdf".
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _service = AccountLibraryService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _CollectionSort _sort = _CollectionSort.dataCriacao;

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sortLabel(_CollectionSort s) {
    switch (s) {
      case _CollectionSort.dataCriacao:
        return 'Data de criação';
      case _CollectionSort.alfabetica:
        return 'Ordem alfabética';
      case _CollectionSort.quantidadeItens:
        return 'Mais itens';
    }
  }

  Future<void> _promptCreateCollection() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Nova Coleção',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ex: Nutrição, Antibióticos...',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kAccountGreen),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await _service.createCollection(name);
    }
  }

  void _showCollectionMenu(PlantCollectionModel col) {
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
                leading: const Icon(Icons.folder_open_rounded, color: kAccountGreen),
                title: Text('Abrir "${col.nome}"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCollection(col);
                },
              ),
              if (!col.isDefault) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Renomear coleção'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _promptRename(col);
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
                    await _service.deleteCollection(col.id);
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

  Future<void> _promptRename(PlantCollectionModel col) async {
    final ctrl = TextEditingController(text: col.nome);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Renomear Coleção'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome da coleção'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
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
    if (newName != null && newName.isNotEmpty) {
      await _service.renameCollection(col.id, newName);
    }
  }

  void _openCollection(PlantCollectionModel col) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionPlantsScreen(
          title: col.nome,
          mode: CollectionPlantsMode.collection,
          collectionId: col.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : kAccountPageBg,
      body: Column(
        children: [
          const BotanicalAppBar(
            title: 'COLEÇÕES',
            uppercaseTitle: true,
          ),

          Expanded(
            child: StreamBuilder<List<PlantCollectionModel>>(
              stream: _service.watchCollections(),
              builder: (context, snapshot) {
                final rawList = snapshot.data ?? [];
                final q = _searchQuery.trim().toLowerCase();
                final filtered = rawList
                    .where((c) => q.isEmpty || c.nome.toLowerCase().contains(q))
                    .toList();

                filtered.sort((a, b) {
                  // Mantém "Favoritos" sempre no topo quando ordenado por data de criação
                  if (_sort == _CollectionSort.dataCriacao) {
                    if (a.isDefault && !b.isDefault) return -1;
                    if (!a.isDefault && b.isDefault) return 1;
                    return a.createdAt.compareTo(b.createdAt);
                  } else if (_sort == _CollectionSort.alfabetica) {
                    return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
                  } else {
                    return b.count.compareTo(a.count);
                  }
                });

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: [
                    // Barra de Pesquisa (fiel a Coleções Conta.pdf)
                    Container(
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

                    const SizedBox(height: 14),

                    // Linha de ordenação ("Data de criação v") + Contador + Botão "+"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PopupMenuButton<_CollectionSort>(
                          initialValue: _sort,
                          onSelected: (s) => setState(() => _sort = s),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _CollectionSort.dataCriacao,
                              child: Text('Data de criação'),
                            ),
                            PopupMenuItem(
                              value: _CollectionSort.alfabetica,
                              child: Text('Ordem alfabética'),
                            ),
                            PopupMenuItem(
                              value: _CollectionSort.quantidadeItens,
                              child: Text('Mais itens'),
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
                                  _sortLabel(_sort),
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
                              '${filtered.length} ${filtered.length == 1 ? 'coleção' : 'coleções'}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : const Color(0xFF7A7A7A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _promptCreateCollection,
                              child: Container(
                                width: 44,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: kAccountGreen,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        rawList.isEmpty)
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
                            'Nenhuma coleção encontrada.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map(
                        (col) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CollectionCard(
                            collection: col,
                            isDark: isDark,
                            onTap: () => _openCollection(col),
                            onMoreTap: () => _showCollectionMenu(col),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final PlantCollectionModel collection;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _CollectionCard({
    required this.collection,
    required this.isDark,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 98,
        decoration: BoxDecoration(
          color: isDark ? SumaColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? SumaColors.darkDivider : const Color(0xFFDCDCDC),
          ),
        ),
        child: Row(
          children: [
            // Bloco verde esquerdo com a árvore Sumaúma branca (fiel a Coleções Conta.pdf e ao verde do Hub)
            Container(
              width: 98,
              height: 98,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isDark ? SumaGradients.darkCard : SumaGradients.searchBar,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Image.asset(
                'icons/ico-branco.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 18),

            // Nome e quantidade de itens
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    collection.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection.count} ${collection.count == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // Botão ⋮ no canto superior direito
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onMoreTap,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 21,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
