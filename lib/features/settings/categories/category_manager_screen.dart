import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/models/app_category.dart';
import '../../../shared/models/transaction.dart';
import '../../../shared/providers/category_provider.dart';
import 'category_editor_sheet.dart';

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppCategory category,
  ) async {
    final s = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCategoryConfirm),
        content: Text(s.deleteCategoryWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && category.id != null) {
      HapticService.medium();
      await ref.read(categoryActionsProvider).remove(category.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isRu = s.locale == AppLocale.ru;
    final catalog = ref.watch(categoryCatalogProvider);
    final custom = catalog.custom;
    final defaults = catalog.all.where((c) => !c.isCustom).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          s.manageCategories,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticService.medium();
          showCategoryEditor(context);
        },
        backgroundColor: const Color(0xFF7C6DED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          s.addCategory,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _SectionLabel(text: s.customCategories),
          const SizedBox(height: 12),
          if (custom.isEmpty)
            _EmptyState(
              title: s.noCustomCategories,
              subtitle: s.noCustomCategoriesHint,
            )
          else
            ...custom.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CategoryRow(
                  category: c,
                  isRu: isRu,
                  onTap: () => showCategoryEditor(context, existing: c),
                  onDelete: () => _confirmDelete(context, ref, c),
                ),
              ),
            ),
          const SizedBox(height: 28),
          _SectionLabel(text: s.defaultCategories),
          const SizedBox(height: 12),
          ...defaults.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryRow(category: c, isRu: isRu),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  final AppCategory category;
  final bool isRu;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _CategoryRow({
    required this.category,
    required this.isRu,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = category.type == TransactionType.income;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: isDark
              ? null
              : Border.all(color: const Color(0xFFDDDDEE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label(isRu),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isIncome ? s.income : s.expenses,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: (isIncome ? AppColors.income : AppColors.expense)
                          .withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.25),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? null
            : Border.all(color: const Color(0xFFDDDDEE), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 36,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
