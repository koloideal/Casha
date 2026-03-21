import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/services/haptic_service.dart';
import '../provider.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(transactionFilterProvider);
    final timeFilter = ref.watch(timeFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _FilterChip(
          label: 'All Time',
          isSelected: timeFilter == TimeFilter.allTime,
          onTap: () => ref.read(timeFilterProvider.notifier).state = TimeFilter.allTime,
        ),
        const SizedBox(width: 6),
        _FilterChip(
          label: 'Month',
          isSelected: timeFilter == TimeFilter.lastMonth,
          onTap: () => ref.read(timeFilterProvider.notifier).state = TimeFilter.lastMonth,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 1,
            height: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(
              isDark ? 0.15 : 0.2,
            ),
          ),
        ),
        _FilterChip(
          label: 'All',
          isSelected: typeFilter == TransactionFilter.all,
          onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.all,
        ),
        const SizedBox(width: 6),
        _FilterChip(
          label: 'Income',
          isSelected: typeFilter == TransactionFilter.income,
          color: AppColors.income,
          onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.income,
        ),
        const SizedBox(width: 6),
        _FilterChip(
          label: 'Expense',
          isSelected: typeFilter == TransactionFilter.expense,
          color: AppColors.expense,
          onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.expense,
        ),
      ],
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
    final chipColor = color ?? AppColors.accent;
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
