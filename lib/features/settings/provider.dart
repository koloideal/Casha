import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
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

  void onCurrencyChanged(String oldCode, String newCode, ExchangeRateService rates) {
    if (state == null) return;
    final converted = rates.convert(state!, oldCode, newCode);
    setBudget(converted);
  }
}

// Currency info: symbol and code
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
  CurrencyNotifier() : super(currencyMap['USD']!) {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currency_code') ?? 'USD';
    state = currencyMap[code] ?? currencyMap['USD']!;
  }

  Future<void> setCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    state = currencyMap[code] ?? currencyMap['USD']!;
    await prefs.setString('currency_code', code);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyInfo>(
  (ref) => CurrencyNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getBool('dark_mode') ?? true) ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('dark_mode', state == ThemeMode.dark);
  }

  Future<void> setThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('dark_mode', isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// Exchange rate service
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExchangeRateService(prefs);
});

final ratesInitProvider = FutureProvider<void>((ref) async {
  await ref.read(exchangeRateServiceProvider).fetchRates();
});

final exportProvider = Provider<ExportService>((ref) {
  return ExportService(ref);
});

class ExportService {
  final Ref _ref;

  ExportService(this._ref);

  Future<String> exportToCSV() async {
    final transactions = _ref.read(transactionsProvider);
    final currency = _ref.read(currencyProvider);
    final fmt = _ref.read(amountFormatProvider);

    // CSV header
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Currency,Note');

    // CSV rows
    for (final tx in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final type = tx.type.name;
      final category = tx.category;
      final amount = formatAmount(tx.currency, tx.amount, fmt);
      final note = tx.note?.replaceAll(',', ';') ?? '';
      buffer.writeln('$date,$type,$category,$amount,${tx.currencyCode},$note');
    }

    // Save to Downloads
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/transactions_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }
}
