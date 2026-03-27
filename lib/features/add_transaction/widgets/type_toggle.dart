import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../shared/models/transaction.dart';
import '../../dashboard/provider.dart';

class TypeToggle extends ConsumerWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final bool isDark;
  final bool isEditing;

  const TypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.isDark,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull ?? [];
    final transferDisabled = accounts.length <= 1;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? null
            : Border.all(color: const Color(0xFFDDDDEE), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeOption(
              icon: Icons.arrow_downward_rounded,
              label: 'Income',
              color: AppColors.income,
              isSelected: selected == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
              isDark: isDark,
              showLock: isEditing && selected == TransactionType.income,
            ),
          ),
          Expanded(
            child: _TypeOption(
              icon: Icons.arrow_upward_rounded,
              label: 'Expense',
              color: AppColors.expense,
              isSelected: selected == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
              isDark: isDark,
              showLock: isEditing && selected == TransactionType.expense,
            ),
          ),
          Expanded(
            child: _TypeOption(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer',
              color: Colors.blueAccent,
              isSelected: selected == TransactionType.transfer,
              onTap: transferDisabled
                  ? null
                  : () => onChanged(TransactionType.transfer),
              isDark: isDark,
              disabled: transferDisabled,
              showLock: isEditing && selected == TransactionType.transfer,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;
  final bool showLock;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.disabled = false,
    this.showLock = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2)
        : color;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected && !disabled
                  ? effectiveColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: isSelected && !disabled
                  ? Border.all(color: effectiveColor, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected && !disabled
                        ? effectiveColor
                        : Theme.of(context).colorScheme.onSurface.withOpacity(
                            disabled ? 0.2 : 0.4,
                          ),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected && !disabled
                          ? effectiveColor
                          : Theme.of(context).colorScheme.onSurface.withOpacity(
                              disabled ? 0.2 : 0.5,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showLock)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.lock_outline,
                size: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}
