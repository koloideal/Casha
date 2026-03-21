import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../settings/provider.dart';
import '../provider.dart';

class BudgetProgress extends ConsumerWidget {
  final double spent;
  final double budget;
  final CurrencyInfo currencyInfo;
  const BudgetProgress({
    super.key,
    required this.spent,
    required this.budget,
    required this.currencyInfo,
  });

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    final progress = budget > 0 ? spent / budget : 0.0;
    final isOver = progress > 1.0;
    final displayPercent = (progress * 100).toStringAsFixed(0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            left: BorderSide(
              color: isOver ? const Color(0xFFE05C6B) : const Color(0xFF7C6DED),
              width: 3,
            ),
            top: _themeBorder(context)?.top ?? BorderSide.none,
            right: _themeBorder(context)?.right ?? BorderSide.none,
            bottom: _themeBorder(context)?.bottom ?? BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '$displayPercent%',
                  style: TextStyle(
                    color: isOver
                        ? const Color(0xFFE05C6B)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isOver ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isOver ? 1.0 : progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver
                      ? const Color(0xFFE05C6B)
                      : (progress > 0.8
                            ? Colors.orange
                            : const Color(0xFF4CAF8C)),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${formatAmount(currencyInfo.symbol, spent, fmt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  'Limit: ${formatAmount(currencyInfo.symbol, budget, fmt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
