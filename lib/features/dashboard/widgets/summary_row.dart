import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../settings/provider.dart';
import '../provider.dart';

class SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final CurrencyInfo currencyInfo;
  final AppStrings strings;
  const SummaryRow({
    super.key,
    required this.income,
    required this.expense,
    required this.currencyInfo,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: strings.income,
            amount: income,
            color: AppColors.income,
            icon: Icons.arrow_downward_rounded,
            currencyInfo: currencyInfo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            label: strings.expenses,
            amount: expense,
            color: AppColors.expense,
            icon: Icons.arrow_upward_rounded,
            currencyInfo: currencyInfo,
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends ConsumerWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final CurrencyInfo currencyInfo;
  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencyInfo,
  });

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: _themeBorder(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatAmount(currencyInfo.symbol, amount, fmt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
