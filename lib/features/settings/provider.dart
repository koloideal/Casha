import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/services/exchange_rate_service.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/providers/amount_format_provider.dart';
import '../dashboard/provider.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, double?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BudgetNotifier(storage.loadBudget(), storage);
});

class BudgetNotifier extends StateNotifier<double?> {
  final dynamic _storage;

  BudgetNotifier(super.initialBudget, this._storage);

  Future<void> setBudget(double? budget) async {
    await _storage.saveBudget(budget);
    state = budget;
  }

  void onCurrencyChanged(
    String oldCode,
    String newCode,
    ExchangeRateService rates,
  ) {
    if (state == null) return;
    final converted = rates.convert(state!, oldCode, newCode);
    setBudget(converted);
  }
}

class CurrencyInfo {
  final String symbol;
  final String code;
  const CurrencyInfo(this.symbol, this.code);
}

const Map<String, CurrencyInfo> currencyMap = {
  'USD': CurrencyInfo('\$', 'USD'),
  'EUR': CurrencyInfo('€', 'EUR'),
  'BYN': CurrencyInfo('Br', 'BYN'),
  'RUB': CurrencyInfo('₽', 'RUB'),
};

class CurrencyNotifier extends StateNotifier<CurrencyInfo> {
  final SharedPreferences _prefs;

  CurrencyNotifier(this._prefs) : super(currencyMap['USD']!) {
    _load();
  }

  void _load() {
    final code = _prefs.getString('currency_code') ?? 'USD';
    state = currencyMap[code] ?? currencyMap['USD']!;
  }

  Future<void> setCurrency(String code) async {
    state = currencyMap[code] ?? currencyMap['USD']!;
    await _prefs.setString('currency_code', code);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyInfo>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _load();
  }

  void _load() {
    final saved = _prefs.getString('theme_mode');
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString('theme_mode', mode.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

enum CardTextColorMode { white, adaptive, black }

class CardTextColorNotifier extends StateNotifier<CardTextColorMode> {
  static const _key = 'card_text_color';
  final SharedPreferences _prefs;

  CardTextColorNotifier(this._prefs)
    : super(_fromString(_prefs.getString(_key)));

  static CardTextColorMode _fromString(String? value) {
    return CardTextColorMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CardTextColorMode.adaptive,
    );
  }

  void set(CardTextColorMode mode) {
    state = mode;
    _prefs.setString(_key, mode.name);
  }
}

final cardTextColorProvider =
    StateNotifierProvider<CardTextColorNotifier, CardTextColorMode>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return CardTextColorNotifier(prefs);
    });

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExchangeRateService(prefs);
});

final ratesInitProvider = FutureProvider<void>((ref) async {
  await ref.read(exchangeRateServiceProvider).fetchRates();
});

final hapticEnabledProvider = StateNotifierProvider<HapticNotifier, bool>((
  ref,
) {
  return HapticNotifier();
});

class HapticNotifier extends StateNotifier<bool> {
  HapticNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    state = HapticService.isEnabled;
  }

  Future<void> toggle(bool value) async {
    await HapticService.setEnabled(value);
    state = value;
    if (value) HapticFeedback.mediumImpact();
  }
}

final showCurrencyConversionsProvider =
    StateNotifierProvider<ShowCurrencyConversionsNotifier, bool>((ref) {
      return ShowCurrencyConversionsNotifier();
    });

class ShowCurrencyConversionsNotifier extends StateNotifier<bool> {
  ShowCurrencyConversionsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('show_currency_conversions') ?? true;
  }

  Future<void> toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_currency_conversions', value);
    state = value;
  }
}

final exportProvider = Provider<ExportService>((ref) {
  return ExportService(ref);
});

class ExportService {
  final Ref _ref;

  ExportService(this._ref);

  Future<String> exportToCSV() async {
    final transactionsAsync = _ref.read(transactionsProvider);
    final transactions = transactionsAsync.valueOrNull ?? [];
    final currency = _ref.read(currencyProvider);
    final fmt = _ref.read(amountFormatProvider);

    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Currency,Note');

    for (final tx in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final type = tx.type.name;
      final category = tx.category;
      final amount = formatAmount(tx.currency, tx.amount, fmt);
      final note = tx.note?.replaceAll(',', ';') ?? '';
      buffer.writeln('$date,$type,$category,$amount,${tx.currencyCode},$note');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/transactions_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }
}
