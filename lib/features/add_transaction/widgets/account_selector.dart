import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/transaction.dart';
import '../../dashboard/provider.dart';
import '../provider.dart';

class AccountSelector extends ConsumerWidget {
  final Transaction? initial;
  final bool showDropdown;
  final VoidCallback onToggleDropdown;
  final GlobalKey indicatorKey;

  const AccountSelector({
    super.key,
    required this.initial,
    required this.showDropdown,
    required this.onToggleDropdown,
    required this.indicatorKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeAccountProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        final txAccountId = ref
            .read(addTransactionProvider(initial))
            .selectedAccountId;
        final Account displayAccount;
        if (txAccountId != null) {
          displayAccount = accounts.firstWhere(
            (a) => a.id == txAccountId,
            orElse: () => accounts.firstWhere(
              (a) => a.isMain,
              orElse: () => accounts.first,
            ),
          );
        } else {
          displayAccount =
              activeAccount ??
              accounts.firstWhere(
                (a) => a.isMain,
                orElse: () => accounts.first,
              );
        }

        final canChangeAccount = activeAccount == null;

        return GestureDetector(
          onTap: canChangeAccount ? onToggleDropdown : null,
          child: Container(
            key: indicatorKey,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF7C6DED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C6DED).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Color(0xFF7C6DED),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    displayAccount.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7C6DED),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (canChangeAccount) ...[
                  const SizedBox(width: 6),
                  Icon(
                    showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 18,
                    color: const Color(0xFF7C6DED),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      error: (_, __) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class AccountDropdownOverlay extends ConsumerWidget {
  final Transaction? initial;
  final VoidCallback onClose;

  const AccountDropdownOverlay({
    super.key,
    required this.initial,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeAccountProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Positioned(
      top: 76,
      left: 20,
      right: MediaQuery.of(context).size.width / 2 + 6,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7C6DED).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: accountsAsync.when(
            data: (accounts) {
              final txAccountId = ref
                  .read(addTransactionProvider(initial))
                  .selectedAccountId;
              final Account displayAccount;
              if (txAccountId != null) {
                displayAccount = accounts.firstWhere(
                  (a) => a.id == txAccountId,
                  orElse: () => accounts.firstWhere(
                    (a) => a.isMain,
                    orElse: () => accounts.first,
                  ),
                );
              } else {
                displayAccount =
                    activeAccount ??
                    accounts.firstWhere(
                      (a) => a.isMain,
                      orElse: () => accounts.first,
                    );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: accounts.map((account) {
                  final isSelected = account.id == displayAccount.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref
                          .read(addTransactionProvider(initial).notifier)
                          .setAccountId(account.id);
                      onClose();
                      HapticService.light();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF7C6DED)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              account.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFF7C6DED)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF7C6DED),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
