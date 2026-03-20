import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import 'provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _budgetController = TextEditingController();
  bool _isEditing = false;
  late NumberFormat _currencyFmt;

  @override
  void initState() {
    super.initState();
    final currencyInfo = ref.read(currencyProvider);
    _currencyFmt = NumberFormat.currency(symbol: currencyInfo.symbol, decimalDigits: 2);
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
    final budget = ref.watch(budgetProvider);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final currencyInfo = ref.watch(currencyProvider);

    // Update currency format when it changes
    _currencyFmt = NumberFormat.currency(symbol: currencyInfo.symbol, decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              'Manage your preferences',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            iconSize: 32,
            color: AppColors.accent,
            onPressed: () => context.push('/add'),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [

            // Theme Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          isDarkMode ? 'Enabled' : 'Disabled',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).setThemeMode(value);
                    },
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Currency Selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
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
                          Icons.attach_money_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Currency',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: ['USD', 'EUR', 'BYN', 'RUB'].map((code) {
                      final info = currencyMap[code]!;
                      final isSelected = currencyInfo.code == code;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(currencyProvider.notifier).setCurrency(code);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withOpacity(0.2)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.divider,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    info.symbol,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    code,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Budget Setting
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
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
                          'Monthly Budget',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          color: AppColors.textSecondary,
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
                            prefixText: '${currencyInfo.symbol} ',
                            hintText: '0.00',
                            helperText: 'Leave empty to remove budget limit',
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
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveBudget,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(80, 40),
                              ),
                              child: const Text('Save'),
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
                              ? _currencyFmt.format(budget)
                              : 'Not set',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: budget != null ? AppColors.accent : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          budget != null
                              ? 'Your monthly spending limit'
                              : 'Set a monthly spending limit to track your budget',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Budget tracking shows on the Dashboard with a progress bar and warning when exceeded.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
