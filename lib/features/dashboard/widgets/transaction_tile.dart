import 'package:collection/collection.dart';
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
import '../../../shared/widgets/byn_sign.dart';
import '../../settings/provider.dart';
import '../provider.dart';

class TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  const TransactionTile({super.key, required this.transaction});

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFDDDDEE),
      width: 1,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final fmt = ref.watch(amountFormatProvider);
    final isTransfer = transaction.category == 'Transfer';
    final isIncome = transaction.type == TransactionType.income;
    final color = isTransfer
        ? const Color(0xFF7C6DED)
        : (isIncome ? AppColors.income : AppColors.expense);
    final catColor = isTransfer
        ? const Color(0xFF7C6DED)
        : (AppCategories.colors[transaction.category] ?? AppColors.accent);
    final catIcon = isTransfer
        ? Icons.swap_horiz_rounded
        : (AppCategories.icons[transaction.category] ?? Icons.category_rounded);

    // Check if we're on Total Balance page
    final activeAccount = ref.watch(activeAccountProvider);
    final displayCurrency =
        activeAccount?.currency ?? ref.watch(currencyProvider).code;
    final showConverted = transaction.currencyCode != displayCurrency;
    final exchangeService = ref.watch(exchangeRateServiceProvider);
    final convertedAmount = showConverted
        ? exchangeService.convert(
            transaction.amount,
            transaction.currencyCode,
            displayCurrency,
          )
        : 0.0;
    final displaySymbol = currencyMap[displayCurrency]?.symbol ?? '';

    // Look up the account name by matching transaction.accountId
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final txAccount = accounts.firstWhereOrNull(
      (a) => a.id == transaction.accountId,
    );

    // Build account label with 10-character limit
    String accountLabel = txAccount?.name ?? '';
    if (accountLabel.length > 10) {
      accountLabel = '${accountLabel.substring(0, 10)}...';
    }

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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isTransfer
                              ? 'Transfer'
                              : s.categoryLabel(transaction.category),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeAccount == null && accountLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _AccountTag(label: accountLabel),
                      ],
                    ],
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
                      DateFormat(
                        'd MMM yyyy · HH:mm',
                        s.dateLocale,
                      ).format(transaction.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                transaction.currencyCode == 'BYN'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            isTransfer ? '' : (isIncome ? '+ ' : '- '),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          BynSign(fontSize: 14, color: color),
                          const SizedBox(width: 2),
                          Text(
                            formatAmount('', transaction.amount, fmt),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        isTransfer
                            ? formatAmount(
                                transaction.currency,
                                transaction.amount,
                                fmt,
                              )
                            : '${isIncome ? '+ ' : '- '}${formatAmount(transaction.currency, transaction.amount, fmt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                if (showConverted) ...[
                  if (displayCurrency == 'BYN')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '≈ ',
                          style: TextStyle(
                            fontSize: 11,
                            color: color.withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                        BynSign(fontSize: 11, color: color.withOpacity(0.5)),
                        const SizedBox(width: 2),
                        Text(
                          formatAmount('', convertedAmount, fmt),
                          style: TextStyle(
                            fontSize: 11,
                            color: color.withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '≈ ${formatAmount(displaySymbol, convertedAmount, fmt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTag extends StatelessWidget {
  final String label;
  const _AccountTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFF0EFFE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFFD0CAFF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(0.55)
                : const Color(0xFF7C6DED),
            letterSpacing: 0.1,
          ),
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
