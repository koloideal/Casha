import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/models/account.dart';
import '../../provider.dart';
import '../../../settings/provider.dart';

class AccountDeleteDialog extends ConsumerWidget {
  final Account? editingAccount;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const AccountDeleteDialog({
    super.key,
    required this.editingAccount,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Account?'),
            content: const Text(
              'Are you sure you want to delete this account? All associated transactions will also be permanently deleted.',
            ),
            actions: [
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  if (editingAccount == null) return;

                  final accountId = editingAccount!.id;

                  onConfirm();

                  final txs = ref.read(transactionsProvider).valueOrNull ?? [];
                  final accountTxs = txs
                      .where((t) => t.accountId == accountId)
                      .toList();
                  for (final t in accountTxs) {
                    await ref.read(transactionsProvider.notifier).delete(t.id);
                  }

                  await ref.read(accountRepositoryProvider).delete(accountId);

                  if (ref.read(hapticEnabledProvider)) {
                    HapticService.medium();
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
