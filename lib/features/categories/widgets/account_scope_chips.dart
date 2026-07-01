import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../dashboard/provider.dart';

class AccountScopeChips extends ConsumerWidget {
  const AccountScopeChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final activeIndex = ref.watch(activeAccountIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _ScopeChip(
                label: s.allAccounts,
                isSelected: activeIndex == 0,
                isDark: isDark,
                onTap: () {
                  ref.read(activeAccountIndexProvider.notifier).set(0);
                  HapticService.selection();
                },
              ),
              if (accounts.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                ),
                const SizedBox(width: 8),
              ],
              ...accounts.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final account = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _ScopeChip(
                    label: account.name,
                    isSelected: activeIndex == index,
                    isDark: isDark,
                    onTap: () {
                      ref.read(activeAccountIndexProvider.notifier).set(index);
                      HapticService.selection();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C6DED).withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF7C6DED), width: 1.5)
              : isDark
              ? null
              : Border.all(color: const Color(0xFFDDDDEE), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF7C6DED)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
