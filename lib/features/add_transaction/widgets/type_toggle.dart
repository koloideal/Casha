import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../shared/models/transaction.dart';

class TypeToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final bool isDark;

  const TypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
            child: GestureDetector(
              onTap: () => onChanged(TransactionType.income),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected == TransactionType.income
                      ? AppColors.income.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: selected == TransactionType.income
                        ? AppColors.income
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(TransactionType.expense),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected == TransactionType.expense
                      ? AppColors.expense.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: selected == TransactionType.expense
                        ? AppColors.expense
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
