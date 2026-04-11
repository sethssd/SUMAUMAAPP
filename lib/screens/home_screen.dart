import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';
import '../widgets/side_menu.dart';
import '../widgets/plant_search_delegate.dart';

// necessita de mais atenção, melhorar padroes de busca e otimizar codigos
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _limit = 20;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _plantas = [];
  DocumentSnapshot? _lastDoc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPlantas();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMore) {
          _fetchPlantas();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlantas() async {
    if (_isLoadingMore) return;
    
    if (_isInitialLoading) {
      setState(() {});
    } else {
      setState(() => _isLoadingMore = true);
    }
    
    try {
      Query query = FirebaseFirestore.instance.collection('plantas').limit(_limit);
      
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }
      
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        _plantas.addAll(snapshot.docs);
      }
    } catch (e) {
      debugPrint("Erro ao carregar plantas: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sumaúma"),
        leading: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  isDark ? 'icons/ico-branco.png' : 'icons/ico-verde.png',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        actions: [
          // Ícone de Pesquisa (Foto 1)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 2. CHAMADA A FUNÇÃO DE BUSCA
              showSearch(context: context, delegate: PlantSearchDelegate());
            },
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPlantas = _plantas.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return data['excluida'] != true;
    }).toList();

    if (filteredPlantas.isEmpty) {
      return const Center(child: Text("Nenhuma planta encontrada."));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredPlantas.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredPlantas.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final planta = filteredPlantas[index];
        final data = planta.data() as Map<String, dynamic>;

        final String modelo3dUrl = data['modelo3dUrl'] ?? '';
        final bool hasModel3D = modelo3dUrl.isNotEmpty;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  Image.network(
                    data['imagemUrl'] ?? 'https://via.placeholder.com/100',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                          Icons.image_not_supported,
                          size: 60,
                          color: Colors.grey,
                        ),
                  ),
                  if (hasModel3D)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.threesixty,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(data['nome'] ?? 'Nome não encontrado'),
            subtitle: Text(data['descricaoCurta'] ?? 'Sem descrição'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(plantaId: planta.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
