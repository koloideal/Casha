import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../provider.dart';

class BudgetSection extends ConsumerStatefulWidget {
  const BudgetSection({super.key});

  @override
  ConsumerState<BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends ConsumerState<BudgetSection> {
  final _budgetController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final budget = ref.read(budgetProvider);
    if (budget != null) {
      _budgetController.text = budget.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final text = _budgetController.text.trim();
    if (text.isEmpty) {
      await ref.read(budgetProvider.notifier).setBudget(null);
    } else {
      final value = double.tryParse(text);
      if (value != null && value > 0) {
        await ref.read(budgetProvider.notifier).setBudget(value);
      }
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final budget = ref.watch(budgetProvider);
    final currencyInfo = ref.watch(currencyProvider);
    final fmt = ref.watch(amountFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.monthlyBudgetSetting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    prefixText: currencyInfo.symbol == 'Br' || currencyInfo.symbol == '₽'
                        ? '${currencyInfo.symbol} '
                        : currencyInfo.symbol,
                    hintText: '0.00',
                    helperText: s.leaveEmptyToRemove,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        final budget = ref.read(budgetProvider);
                        _budgetController.text = budget?.toStringAsFixed(2) ?? '';
                        setState(() => _isEditing = false);
                      },
                      child: Text(s.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveBudget,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 40),
                      ),
                      child: Text(s.save),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget != null
                      ? formatAmount(currencyInfo.symbol, budget, fmt)
                      : s.budgetNone,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: budget != null ? AppColors.accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  budget != null
                      ? s.yourMonthlySpendingLimit
                      : s.setMonthlySpendingLimit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
