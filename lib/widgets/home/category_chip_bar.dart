import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Lista horizontal de chips para filtrar plantas por categoria.
/// [categories] inclui sempre "Todas" no início.
/// [selected] é a categoria atualmente ativa (null = sem filtro).
class CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static const _iconMap = <String, IconData>{
    'Medicinais': Icons.local_pharmacy_outlined,
    'Frutíferas': Icons.emoji_food_beverage_outlined,
    'Aromáticas': Icons.spa_outlined,
    'Madeireiras': Icons.forest_outlined,
    'Ornamentais': Icons.local_florist_outlined,
    'Alimentícias': Icons.restaurant_menu_outlined,
    'Tóxicas': Icons.warning_amber_rounded,
    'Aquáticas': Icons.water_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Todas"
          _CategoryChip(
            label: 'Todas',
            icon: Icons.apps_rounded,
            isSelected: selected == null,
            isDark: isDark,
            onTap: () => onSelected(null),
          ),
          ...categories.map((cat) => _CategoryChip(
                label: cat,
                icon: _iconMap[cat] ?? Icons.eco_outlined,
                isSelected: selected == cat,
                isDark: isDark,
                onTap: () => onSelected(selected == cat ? null : cat),
              )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? SumaColors.greenBright
              : (isDark
                  ? SumaColors.darkSurface
                  : const Color(0xFFEBF5EE)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? SumaColors.greenBright
                : (isDark
                    ? SumaColors.darkDivider
                    : const Color(0xFFB7DFC6)),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white60 : SumaColors.greenMid),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : SumaColors.greenDeep),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
