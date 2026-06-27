import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/models/app_category.dart';

class CategoryPicker extends ConsumerWidget {
  final List<AppCategory> categories;
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
    final isRu = s.locale == AppLocale.ru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categories.map((cat) {
          final isSelected = cat.key == selected;
          final color = cat.color;
          return GestureDetector(
            onTap: () {
              HapticService.light();
              onChanged(cat.key);
            },
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
                          : Border.all(
                              color: const Color(0xFFDDDDEE), width: 1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    color: isSelected
                        ? color
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      cat.label(isRu),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? color
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        _AddCategoryChip(label: s.addCategory),
      ],
    );
  }
}

class _AddCategoryChip extends StatelessWidget {
  final String label;

  const _AddCategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/settings/categories');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.accent, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
