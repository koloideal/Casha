import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/haptic_service.dart';
import '../provider.dart';

class FilterChips extends ConsumerWidget {
  final AppStrings strings;
  const FilterChips({super.key, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(transactionFilterProvider);
    final timeFilter = ref.watch(timeFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _FilterChip(
            label: strings.filterAllTime,
            isSelected: timeFilter == TimeFilter.allTime,
            onTap: () => ref.read(timeFilterProvider.notifier).set(
                TimeFilter.allTime),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: strings.filterMonth,
            isSelected: timeFilter == TimeFilter.lastMonth,
            onTap: () => ref.read(timeFilterProvider.notifier).set(
                TimeFilter.lastMonth),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 1,
              height: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(isDark ? 0.15 : 0.2),
            ),
          ),
          _FilterChip(
            label: strings.filterAll,
            isSelected: typeFilter == TransactionFilter.all,
            onTap: () => ref.read(transactionFilterProvider.notifier).set(
                TransactionFilter.all),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: strings.filterIncome,
            isSelected: typeFilter == TransactionFilter.income,
            color: AppColors.income,
            onTap: () => ref.read(transactionFilterProvider.notifier).set(
                TransactionFilter.income),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: strings.filterExpense,
            isSelected: typeFilter == TransactionFilter.expense,
            color: AppColors.expense,
            onTap: () => ref.read(transactionFilterProvider.notifier).set(
                TransactionFilter.expense),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: strings.filterTransfer,
            isSelected: typeFilter == TransactionFilter.transfer,
            color: Colors.blueAccent,
            onTap: () => ref.read(transactionFilterProvider.notifier).set(
                TransactionFilter.transfer),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF7C6DED);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: chipColor, width: 1.5)
              : isDark
              ? null
              : Border.all(color: const Color(0xFFDDDDEE), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12).merge(
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? chipColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
