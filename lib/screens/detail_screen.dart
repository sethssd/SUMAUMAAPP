import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../utils/app_theme.dart';
import '../widgets/detail/detail_hero_header.dart';
import '../widgets/detail/detail_3d_viewer.dart';
import '../widgets/detail/tabs/geral_tab.dart';
import '../widgets/detail/tabs/cientifico_tab.dart';
import '../widgets/detail/tabs/referencias_tab.dart';

/// Tela de detalhes de uma planta.
/// Responsabilidades: fetch do Firestore (cache-first), controle das 3 abas
/// e injeção do PlantModel nos sub-widgets do diretório widgets/detail/.
class DetailScreen extends StatefulWidget {
  final String plantaId;
  const DetailScreen({super.key, required this.plantaId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlantModel? _plant;
  bool _isLoading = true;

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
    final docRef = FirebaseFirestore.instance.collection('plantas').doc(widget.plantaId);
    DocumentSnapshot? snap;
    try {
      // 1. Tenta cache local para resposta instantânea
      snap = await docRef.get(const GetOptions(source: Source.cache));
      if (!snap.exists) throw Exception('Not in cache');
    } catch (_) {
      // 2. Fallback para servidor no primeiro acesso
      try {
        snap = await docRef.get(const GetOptions(source: Source.server));
      } catch (e) {
        debugPrint('Erro ao carregar planta do servidor: $e');
      }
    }
    if (mounted) {
      setState(() {
        if (snap != null && snap.exists) _plant = PlantModel.fromSnapshot(snap);
        _isLoading = false;
      });
    }
  }

  Widget _buildPremiumTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : SumaColors.greenLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF142F23) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: SumaColors.greenBright,
        unselectedLabelColor: isDark ? Colors.white.withValues(alpha: 0.5) : SumaColors.greenMid.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [Tab(text: 'Geral'), Tab(text: 'Científico'), Tab(text: 'Artigos')],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_plant == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Planta não encontrada.')));
    }

    final plant = _plant!;

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : const Color(0xFFF6FBF7),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: false,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: DetailHeroHeader(plant: plant),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(children: [
                  const SizedBox(height: 20),
                  _buildPremiumTabBar(isDark),
                  const SizedBox(height: 8),
                ]),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    GeralTab(plant: plant),
                    CientificoTab(plant: plant),
                    ReferenciasTab(plant: plant),
                  ],
                ),
              ),
            ]),
          ),
          if (plant.modelo3dUrl.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                color: isDark ? SumaColors.darkBg : const Color(0xFFF6FBF7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Detail3dViewer(url: plant.modelo3dUrl, nome: plant.nome)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16593A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Modelo 3D', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
