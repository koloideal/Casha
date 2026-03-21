import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../shared/models/transaction.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/utils/currency_utils.dart';

class TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  const TransactionTile({super.key, required this.transaction});

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final fmt = ref.watch(amountFormatProvider);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final catColor =
        AppCategories.colors[transaction.category] ?? AppColors.accent;
    final catIcon =
        AppCategories.icons[transaction.category] ?? Icons.category_rounded;

    return GestureDetector(
      onTap: () => context.push('/add', extra: transaction),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: _themeBorder(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.categoryLabel(transaction.category),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Text(
                      transaction.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      DateFormat('d MMM yyyy · HH:mm', s.dateLocale).format(transaction.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+ ' : '- '}${formatAmount(transaction.currency, transaction.amount, fmt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final AppStrings strings;
  const EmptyState({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.noTransactions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.addFirstTx,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
