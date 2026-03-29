import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/transaction.dart';
import '../../dashboard/provider.dart';
import '../provider.dart';

class AccountRow extends ConsumerWidget {
  final Transaction? initial;
  final bool showFromDropdown;
  final bool showToDropdown;
  final VoidCallback onToggleFromDropdown;
  final VoidCallback onToggleToDropdown;
  final GlobalKey fromIndicatorKey;
  final GlobalKey toIndicatorKey;
  final String? fromAccountError;
  final String? toAccountError;
  final bool isDark;
  final bool isFromAccountLocked;
  final bool isToAccountLocked;

  const AccountRow({
    super.key,
    required this.initial,
    required this.showFromDropdown,
    required this.showToDropdown,
    required this.onToggleFromDropdown,
    required this.onToggleToDropdown,
    required this.fromIndicatorKey,
    required this.toIndicatorKey,
    this.fromAccountError,
    this.toAccountError,
    required this.isDark,
    this.isFromAccountLocked = false,
    this.isToAccountLocked = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final state = ref.watch(addTransactionProvider(initial));
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull ?? [];
    final isTransfer = state.type == TransactionType.transfer;

    if (isTransfer && accounts.length == 2 && state.selectedAccountId != null) {
      final otherId = accounts
          .firstWhere(
            (a) => a.id != state.selectedAccountId,
            orElse: () => accounts.first,
          )
          .id;
      if (state.toAccountId != otherId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(addTransactionProvider(initial).notifier)
              .setToAccountId(otherId);
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.accountPlaceholder,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        if (isTransfer)
          _TransferAccountRow(
            initial: initial,
            accounts: accounts,
            showFromDropdown: showFromDropdown,
            showToDropdown: showToDropdown,
            onToggleFromDropdown: onToggleFromDropdown,
            onToggleToDropdown: onToggleToDropdown,
            fromIndicatorKey: fromIndicatorKey,
            toIndicatorKey: toIndicatorKey,
            fromAccountError: fromAccountError,
            toAccountError: toAccountError,
            isDark: isDark,
            isFromAccountLocked: isFromAccountLocked,
            isToAccountLocked: isToAccountLocked,
          )
        else
          _SingleAccountSelector(
            initial: initial,
            accounts: accounts,
            showDropdown: showFromDropdown,
            onToggleDropdown: onToggleFromDropdown,
            indicatorKey: fromIndicatorKey,
            error: fromAccountError,
            isDark: isDark,
            selectAccountText: s.selectAccount,
          ),
      ],
    );
  }
}

class _SingleAccountSelector extends ConsumerWidget {
  final Transaction? initial;
  final List<Account> accounts;
  final bool showDropdown;
  final VoidCallback onToggleDropdown;
  final GlobalKey indicatorKey;
  final String? error;
  final bool isDark;
  final String selectAccountText;

  const _SingleAccountSelector({
    required this.initial,
    required this.accounts,
    required this.showDropdown,
    required this.onToggleDropdown,
    required this.indicatorKey,
    this.error,
    required this.isDark,
    required this.selectAccountText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addTransactionProvider(initial));
    final activeAccount = ref.watch(activeAccountProvider);

    final selectedAccountId = state.selectedAccountId;
    final Account? displayAccount;

    if (selectedAccountId != null) {
      displayAccount = accounts.firstWhere(
        (a) => a.id == selectedAccountId,
        orElse: () => accounts.isNotEmpty
            ? accounts.first
            : Account(
                id: 0,
                name: '',
                currency: 'USD',
                isMain: false,
                sortOrder: 0,
                createdAt: DateTime.now(),
              ),
      );
    } else {
      displayAccount =
          activeAccount ?? (accounts.isNotEmpty ? accounts.first : null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggleDropdown,
          child: Container(
            key: indicatorKey,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: error != null
                  ? const Color(0xFFE05C6B).withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? const Color(0xFFE05C6B)
                    : isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFDDDDEE),
                width: error != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: error != null
                      ? const Color(0xFFE05C6B)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayAccount?.name ?? selectAccountText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: displayAccount != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFE05C6B)),
          ),
        ],
      ],
    );
  }
}

class _TransferAccountRow extends ConsumerWidget {
  final Transaction? initial;
  final List<Account> accounts;
  final bool showFromDropdown;
  final bool showToDropdown;
  final VoidCallback onToggleFromDropdown;
  final VoidCallback onToggleToDropdown;
  final GlobalKey fromIndicatorKey;
  final GlobalKey toIndicatorKey;
  final String? fromAccountError;
  final String? toAccountError;
  final bool isDark;
  final bool isFromAccountLocked;
  final bool isToAccountLocked;

  const _TransferAccountRow({
    required this.initial,
    required this.accounts,
    required this.showFromDropdown,
    required this.showToDropdown,
    required this.onToggleFromDropdown,
    required this.onToggleToDropdown,
    required this.fromIndicatorKey,
    required this.toIndicatorKey,
    this.fromAccountError,
    this.toAccountError,
    required this.isDark,
    this.isFromAccountLocked = false,
    this.isToAccountLocked = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final state = ref.watch(addTransactionProvider(initial));
    final activeAccount = ref.watch(activeAccountProvider);

    final selectedAccountId = state.selectedAccountId;
    final toAccountId = state.toAccountId;

    final Account? fromAccount;
    if (selectedAccountId != null) {
      fromAccount = accounts.firstWhere(
        (a) => a.id == selectedAccountId,
        orElse: () => accounts.isNotEmpty
            ? accounts.first
            : Account(
                id: 0,
                name: '',
                currency: 'USD',
                isMain: false,
                sortOrder: 0,
                createdAt: DateTime.now(),
              ),
      );
    } else {
      if (activeAccount == null && initial == null) {
        fromAccount = null;
      } else {
        fromAccount =
            activeAccount ?? (accounts.isNotEmpty ? accounts.first : null);
      }
    }

    final Account? toAccount = toAccountId != null && accounts.isNotEmpty
        ? accounts.firstWhere(
            (a) => a.id == toAccountId,
            orElse: () => accounts.first,
          )
        : null;

    final autoSelectEnabled = accounts.length == 2;

    return Row(
      children: [
        Expanded(
          child: _AccountHalf(
            account: fromAccount,
            label: 'From',
            showDropdown: showFromDropdown,
            onToggle: isFromAccountLocked ? null : onToggleFromDropdown,
            indicatorKey: fromIndicatorKey,
            error: fromAccountError,
            isDark: isDark,
            disabled: isFromAccountLocked,
            selectText: s.selectAccount,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.swap_horiz_rounded,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        Expanded(
          child: _AccountHalf(
            account: toAccount,
            label: 'To',
            showDropdown: showToDropdown,
            onToggle: (autoSelectEnabled || isToAccountLocked)
                ? null
                : onToggleToDropdown,
            indicatorKey: toIndicatorKey,
            error: toAccountError,
            isDark: isDark,
            disabled: autoSelectEnabled || isToAccountLocked,
            selectText: s.selectAccount,
          ),
        ),
      ],
    );
  }
}

class _AccountHalf extends StatelessWidget {
  final Account? account;
  final String label;
  final bool showDropdown;
  final VoidCallback? onToggle;
  final GlobalKey indicatorKey;
  final String? error;
  final bool isDark;
  final bool disabled;
  final String selectText;

  const _AccountHalf({
    required this.account,
    required this.label,
    required this.showDropdown,
    required this.onToggle,
    required this.indicatorKey,
    this.error,
    required this.isDark,
    this.disabled = false,
    required this.selectText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: disabled ? null : onToggle,
          child: Container(
            key: indicatorKey,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: error != null
                  ? const Color(0xFFE05C6B).withOpacity(0.1)
                  : disabled
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? const Color(0xFFE05C6B)
                    : isDark
                    ? Colors.white.withOpacity(disabled ? 0.05 : 0.1)
                    : const Color(0xFFDDDDEE),
                width: error != null ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface
                            .withOpacity(disabled ? 0.3 : 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (onToggle != null)
                      Icon(
                        showDropdown
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account?.name ?? selectText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: account != null
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(
                            disabled ? 0.5 : 1.0,
                          )
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
