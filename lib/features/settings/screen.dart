import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/biometric_service.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/providers/amount_format_provider.dart';
import '../dashboard/provider.dart';
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

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: const Text('This will permanently delete all your transaction history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Are you absolutely sure?'),
                  content: const Text('All transactions will be deleted forever. There is no way to recover them.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: const Text('No, keep them'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).clearAll();
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All transactions deleted')),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C6B)),
                      child: const Text('Yes, delete everything'),
                    ),
                  ],
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C6B)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final currencyInfo = ref.watch(currencyProvider);
    final fmt = ref.watch(amountFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _currencyFmt = NumberFormat.currency(symbol: currencyInfo.symbol, decimalDigits: 2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'Manage your preferences',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1),
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
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          isDarkMode ? 'Enabled' : 'Disabled',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

            const _BiometricSection(),

            Container(
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                              final oldCode = ref.read(currencyProvider).code;
                              final rates = ref.read(exchangeRateServiceProvider);
                              ref.read(budgetProvider.notifier).onCurrencyChanged(oldCode, code, rates);
                              ref.read(currencyProvider.notifier).setCurrency(code);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withOpacity(0.2)
                                    : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected 
                                    ? Border.all(color: AppColors.accent, width: 1.5)
                                    : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    info.symbol,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    code,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

            Container(
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
                          Icons.format_list_numbered_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Amount Format',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...AmountFormat.values.map((format) {
                    final isSelected = fmt == format;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(amountFormatProvider.notifier).set(format),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withOpacity(0.2)
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: AppColors.accent, width: 1.5)
                                : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                format.label,
                                style: TextStyle(
                                  color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                              Text(
                                format.example.replaceFirst('SYM', currencyInfo.symbol),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            Container(
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
                          'Monthly Budget',
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
                              ? formatAmount(currencyInfo.symbol, budget, fmt)
                              : 'Not set',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: budget != null ? AppColors.accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          budget != null
                              ? 'Your monthly spending limit'
                              : 'Set a monthly spending limit to track your budget',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: const Color(0xFFE05C6B).withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmClearData(context, ref),
                icon: const Icon(Icons.delete_forever, color: Color(0xFFE05C6B)),
                label: const Text(
                  'Clear All Transactions',
                  style: TextStyle(color: Color(0xFFE05C6B)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFE05C6B).withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.white30),
                    children: [
                      TextSpan(
                        text: 'casha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                      TextSpan(
                        text: '  powered with ❤️ by  ',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(
                        text: 'kolo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricSection extends StatefulWidget {
  const _BiometricSection();

  @override
  State<_BiometricSection> createState() => _BiometricSectionState();
}

class _BiometricSectionState extends State<_BiometricSection> {
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _onToggle(bool val) async {
    if (val) {
      final ok = await BiometricService.authenticate();
      if (!ok) return;
    }
    await BiometricService.setEnabled(val);
    if (mounted) setState(() => _enabled = val);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_available) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fingerprint,
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
                      'Biometric Lock',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      'Require fingerprint on app launch',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: _onToggle,
                activeColor: const Color(0xFF7C6DED),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
