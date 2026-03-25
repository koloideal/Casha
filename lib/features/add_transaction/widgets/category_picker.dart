import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';

class CategoryPicker extends ConsumerWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        final color = AppCategories.colors[cat] ?? AppColors.accent;
        final icon = AppCategories.icons[cat] ?? Icons.category_rounded;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color, width: 1.5)
                  : (isDark
                        ? null
                        : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? color
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  s.categoryLabel(cat),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? color
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
