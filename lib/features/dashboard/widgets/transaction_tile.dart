import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../shared/models/transaction.dart';
import '../../../shared/models/account.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/providers/category_provider.dart';
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
    final isRu = s.locale == AppLocale.ru;
    final fmt = ref.watch(amountFormatProvider);
    final catalog = ref.watch(categoryCatalogProvider);
    final isTransfer = transaction.category == 'Transfer';
    final isIncome = transaction.type == TransactionType.income;
    final color = isTransfer
        ? const Color(0xFF7C6DED)
        : (isIncome ? AppColors.income : AppColors.expense);
    final catColor = isTransfer
        ? const Color(0xFF7C6DED)
        : catalog.colorFor(transaction.category);
    final catIcon = isTransfer
        ? Icons.swap_horiz_rounded
        : catalog.iconFor(transaction.category);
    final catLabel = catalog.labelFor(transaction.category, isRu);

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

    final accounts = ref.watch(accountsProvider).value ?? [];
    final txAccount = accounts.firstWhereOrNull(
      (a) => a.id == transaction.accountId,
    );

    String accountLabel = txAccount?.name ?? '';
    if (accountLabel.length > 10) {
      accountLabel = '${accountLabel.substring(0, 10)}...';
    }

    final pairs = ref.watch(transferPairsProvider);
    final counterpart = pairs[transaction.id];

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
                        child: isTransfer
                            ? _buildTransferLabel(
                                context,
                                ref,
                                counterpart,
                                accounts,
                                activeAccount,
                              )
                            : Text(
                                catLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (!isTransfer &&
                          activeAccount == null &&
                          accountLabel.isNotEmpty) ...[
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
                            _getAmountPrefix(
                              isTransfer,
                              isIncome,
                              activeAccount,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _getAmountColor(
                                    context,
                                    isTransfer,
                                    isIncome,
                                    activeAccount,
                                    color,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          BynSign(
                            fontSize: 14,
                            color: _getAmountColor(
                              context,
                              isTransfer,
                              isIncome,
                              activeAccount,
                              color,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatAmount('', transaction.amount, fmt),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _getAmountColor(
                                    context,
                                    isTransfer,
                                    isIncome,
                                    activeAccount,
                                    color,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        '${_getAmountPrefix(isTransfer, isIncome, activeAccount)}${formatAmount(transaction.currency, transaction.amount, fmt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getAmountColor(
                            context,
                            isTransfer,
                            isIncome,
                            activeAccount,
                            color,
                          ),
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

  Widget _buildTransferLabel(
    BuildContext context,
    WidgetRef ref,
    Transaction? counterpart,
    List<Account> accounts,
    Account? activeAccount,
  ) {
    final s = ref.watch(stringsProvider);
    if (counterpart == null) {
      return Text(
        s.transferLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    final isExpense = transaction.type == TransactionType.expense;
    final sourceAccountId = isExpense
        ? transaction.accountId
        : counterpart.accountId;
    final destAccountId = isExpense
        ? counterpart.accountId
        : transaction.accountId;

    final sourceAccountName = _accountName(accounts, sourceAccountId);
    final destAccountName = _accountName(accounts, destAccountId);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (activeAccount == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.transferLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: _TransferChip(
              label: '$sourceAccountName → $destAccountName',
              icon: Icons.swap_horiz_rounded,
            ),
          ),
        ],
      );
    }

    if (isExpense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.transferLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            s.transferTo,
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(child: _TransferChip(label: destAccountName, icon: null)),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.transferLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            s.transferFrom,
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(child: _TransferChip(label: sourceAccountName, icon: null)),
        ],
      );
    }
  }

  String _accountName(List<Account> accounts, int? id) {
    if (id == null) return '?';
    return accounts.firstWhereOrNull((a) => a.id == id)?.name ?? '?';
  }

  String _getAmountPrefix(
    bool isTransfer,
    bool isIncome,
    Account? activeAccount,
  ) {
    if (isTransfer && activeAccount == null && !isIncome) {
      return '';
    }
    return isIncome ? '+ ' : '\u2212 ';
  }

  Color _getAmountColor(
    BuildContext context,
    bool isTransfer,
    bool isIncome,
    Account? activeAccount,
    Color defaultColor,
  ) {
    if (isTransfer && activeAccount == null && !isIncome) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.8);
    }
    if (isTransfer) {
      return isIncome ? AppColors.income : AppColors.expense;
    }
    return defaultColor;
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

class _TransferChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _TransferChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF7C6DED).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C6DED).withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: const Color(0xFF7C6DED)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7C6DED),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
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
