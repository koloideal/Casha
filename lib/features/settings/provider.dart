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

class CurrencyInfo {
  final String symbol;
  final String code;
  const CurrencyInfo(this.symbol, this.code);
}

const Map<String, CurrencyInfo> currencyMap = {
  'USD': CurrencyInfo('\$', 'USD'),
  'EUR': CurrencyInfo('€', 'EUR'),
  'BYN': CurrencyInfo('', 'BYN'),
  'RUB': CurrencyInfo('₽', 'RUB'),
};

class CurrencyNotifier extends Notifier<CurrencyInfo> {
  @override
  CurrencyInfo build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString('currency_code') ?? 'USD';
    return currencyMap[code] ?? currencyMap['USD']!;
  }

  Future<void> setCurrency(String code) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = currencyMap[code] ?? currencyMap['USD']!;
    await prefs.setString('currency_code', code);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, CurrencyInfo>(
  CurrencyNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString('theme_mode');
    if (saved == 'dark') {
      return ThemeMode.dark;
    } else if (saved == 'light') {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = mode;
    await prefs.setString('theme_mode', mode.name);
  }
}

final themeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

enum CardTextColorMode { white, adaptive, black }

class CardTextColorNotifier extends Notifier<CardTextColorMode> {
  static const _key = 'card_text_color';

  @override
  CardTextColorMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _fromString(prefs.getString(_key));
  }

  static CardTextColorMode _fromString(String? value) {
    return CardTextColorMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CardTextColorMode.adaptive,
    );
  }

  void set(CardTextColorMode mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    state = mode;
    prefs.setString(_key, mode.name);
  }
}

final cardTextColorProvider =
    NotifierProvider<CardTextColorNotifier, CardTextColorMode>(
      CardTextColorNotifier.new,
    );

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExchangeRateService(prefs);
});

final cardHeightProvider = NotifierProvider<CardHeightNotifier, double>(
  CardHeightNotifier.new,
);

class CardHeightNotifier extends Notifier<double> {
  static const _key = 'card_height';
  static const minHeight = 140.0;
  static const maxHeight = 200.0;
  static const _defaultHeight = 200.0;

  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getDouble(_key);
    if (saved == null) return _defaultHeight;
    return saved.clamp(minHeight, maxHeight);
  }

  void set(double height) {
    final clamped = height.clamp(minHeight, maxHeight);
    state = clamped;
    ref.read(sharedPreferencesProvider).setDouble(_key, clamped);
  }
}

final ratesInitProvider = FutureProvider<void>((ref) async {
  await ref.read(exchangeRateServiceProvider).fetchRates();
});

final hapticEnabledProvider = NotifierProvider<HapticNotifier, bool>(
  HapticNotifier.new,
);

class HapticNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
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
    NotifierProvider<ShowCurrencyConversionsNotifier, bool>(
      ShowCurrencyConversionsNotifier.new,
    );

class ShowCurrencyConversionsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
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
    final transactions = transactionsAsync.value ?? [];
    final fmt = _ref.read(amountFormatProvider);

    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Currency,Note');

    for (final tx in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final type = tx.type.name;
      final category = tx.category;
      final sym = currencyMap[tx.currencyCode]?.symbol ?? '';
      final amount = formatAmount(sym, tx.amount, fmt);
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
