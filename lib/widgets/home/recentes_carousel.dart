import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../utils/app_theme.dart';
import '../../screens/detail_screen.dart';
import 'todas_plantas_hub_card.dart';

/// Seção "Adicionados" no Hub Inicial: exibe apenas as 4 plantas mais recentes
/// em um grid 2x2 e possui o botão "Explorar", que abre a aba/tela dedicada
/// listando todas as 10 plantas adicionadas recentemente (últimos 3 dias + fallback).
class RecentesCarousel extends StatelessWidget {
  final List<PlantModel> plantas;
  final String title;
  final VoidCallback? onExploreTap;

  const RecentesCarousel({
    super.key,
    required this.plantas,
    this.title = 'Adicionados',
    this.onExploreTap,
  });

  void _openExplorar(BuildContext context) {
    if (onExploreTap != null) {
      onExploreTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionadosExplorarScreen(plantas: plantas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (plantas.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Na Home ficam expostas apenas as 4 mais recentes (grid 2x2)
    final items = plantas.take(4).toList();

    final List<List<PlantModel>> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(items.sublist(i, (i + 2 > items.length) ? items.length : i + 2));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 115),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0F3D1E), Color(0xFF072310)]
              : const [Color(0xFF007A1E), Color(0xFF074714)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho "Adicionados" + "Explorar"
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => _openExplorar(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Text(
                      'Explorar',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Grid 2x2 com as 4 plantas mais recentes
          for (int r = 0; r < rows.length; r++) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _AdicionadoGridCard(
                      plant: rows[r][0],
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: rows[r].length > 1
                        ? _AdicionadoGridCard(
                            plant: rows[r][1],
                            isDark: isDark,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (r < rows.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

/// Aba/Tela acionada pelo botão "Explorar" dentro da seção Adicionados,
/// exibindo as 10 plantas adicionadas recentemente (últimos 3 dias + fallback).
class AdicionadosExplorarScreen extends StatelessWidget {
  final List<PlantModel> plantas;

  const AdicionadosExplorarScreen({
    super.key,
    required this.plantas,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = plantas.take(10).toList();

    final List<List<PlantModel>> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(items.sublist(i, (i + 2 > items.length) ? items.length : i + 2));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionados Recentemente'),
        backgroundColor: isDark ? SumaColors.darkAppBar : const Color(0xFF007A1E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0F3D1E), Color(0xFF072310)]
                : const [Color(0xFF007A1E), Color(0xFF074714)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
              child: Text(
                'Mostrando as ${items.length} plantas adicionadas mais recentemente',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            for (int r = 0; r < rows.length; r++) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _AdicionadoGridCard(
                        plant: rows[r][0],
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: rows[r].length > 1
                          ? _AdicionadoGridCard(
                              plant: rows[r][1],
                              isDark: isDark,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (r < rows.length - 1) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdicionadoGridCard extends StatelessWidget {
  final PlantModel plant;
  final bool isDark;

  const _AdicionadoGridCard({
    required this.plant,
    required this.isDark,
  });

  void _openDetail(BuildContext context, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(plantaId: plant.id, initialTab: initialTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pills = buildPlantPills(
      plant,
      includeResumo: true,
      includeManualAspects: false,
    );
    final endereco = plant.enderecoPrincipal;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? SumaColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto no topo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 138,
                width: double.infinity,
                child: plant.imagemUrl.isNotEmpty
                    ? Image.network(
                        plant.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SumaColors.greenDeep.withValues(alpha: 0.4),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white54,
                            size: 36,
                          ),
                        ),
                      )
                    : Container(
                        color: SumaColors.greenDeep.withValues(alpha: 0.4),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white54,
                          size: 36,
                        ),
                      ),
              ),
            ),

            // Conteúdo do card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da planta
                    Text(
                      plant.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),

                    // Endereço / Localização (se houver)
                    if (endereco.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: isDark
                                ? SumaColors.greenSage
                                : const Color(0xFF147A2E),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              endereco,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                height: 1.2,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Pílulas automáticas (Áudio, Modelo 3D, Artigos Científicos, Resumo, Científico, Visitação)
                    if (pills.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: pills
                            .map(
                              (pill) => PlantAspectPill(
                                data: pill,
                                onTap: () => _openDetail(
                                  context,
                                  initialTab: pill.targetTab,
                                ),
                              ),
                            )
                            .toList(),
                      ),

                    const Spacer(),
                    const SizedBox(height: 12),

                    // Botão "Saiba Mais >" centralizado na base
                    Center(
                      child: InkWell(
                        onTap: () => _openDetail(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Saiba Mais',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? SumaColors.greenSage
                                      : const Color(0xFF0A5C1A),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: isDark
                                    ? SumaColors.greenSage
                                    : const Color(0xFF0A5C1A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
