import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/haptic_service.dart';
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
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearDataConfirm),
        content: Text(s.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: Text(s.areYouSure),
                  content: Text(s.allTransactionsWillBeDeleted),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: Text(s.noKeepThem),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).clearAll();
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.allTransactionsDeleted)),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C6B)),
                      child: Text(s.yesDeleteEverything),
                    ),
                  ],
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C6B)),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
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
              s.settings,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              s.managePreferences,
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
                          s.darkMode,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          isDarkMode ? s.enabled : s.disabled,
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

            Consumer(
              builder: (context, ref, _) {
                final enabled = ref.watch(hapticEnabledProvider);
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
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
                          Icons.vibration_rounded,
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
                              s.hapticFeedback,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            Text(
                              s.vibrationOnInteractions,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: (val) => ref.read(hapticEnabledProvider.notifier).toggle(val),
                        activeColor: const Color(0xFF7C6DED),
                      ),
                    ],
                  ),
                );
              },
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
                          Icons.language_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.language,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final currentLocale = ref.watch(localeProvider);
                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.en),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: currentLocale == AppLocale.en
                                      ? AppColors.accent.withOpacity(0.2)
                                      : Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: currentLocale == AppLocale.en
                                      ? Border.all(color: AppColors.accent, width: 1.5)
                                      : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
                                ),
                                child: Text(
                                  s.langEn,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: currentLocale == AppLocale.en
                                        ? AppColors.accent
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: currentLocale == AppLocale.en ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.ru),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: currentLocale == AppLocale.ru
                                      ? AppColors.accent.withOpacity(0.2)
                                      : Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: currentLocale == AppLocale.ru
                                      ? Border.all(color: AppColors.accent, width: 1.5)
                                      : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
                                ),
                                child: Text(
                                  s.langRu,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: currentLocale == AppLocale.ru
                                        ? AppColors.accent
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: currentLocale == AppLocale.ru ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
                          Icons.attach_money_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.currency,
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
                          s.amountFormat,
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
            ),
            
            const SizedBox(height: 24),

            Text(
              s.dangerZone,
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
                label: Text(
                  s.clearAllTransactions,
                  style: const TextStyle(color: Color(0xFFE05C6B)),
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
                child: Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final baseColor = isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.25);
                    final emphasisColor = isDark
                        ? Colors.white.withOpacity(0.35)
                        : Colors.black.withOpacity(0.35);
                    
                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: baseColor),
                        children: [
                          TextSpan(
                            text: 'casha',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: emphasisColor,
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
                              color: emphasisColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricSection extends ConsumerStatefulWidget {
  const _BiometricSection();

  @override
  ConsumerState<_BiometricSection> createState() => _BiometricSectionState();
}

class _BiometricSectionState extends ConsumerState<_BiometricSection> {
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
      HapticService.light();
    }
    await BiometricService.setEnabled(val);
    if (mounted) setState(() => _enabled = val);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_available) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer(
      builder: (context, ref, _) {
        final s = ref.watch(stringsProvider);
        
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
                          s.biometricLock,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          s.requireFingerprint,
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
      },
    );
  }
}
