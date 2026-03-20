import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _primaryUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _fallbackUrl =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json';
  static const String _cacheKey = 'exchange_rates';

  static const Map<String, double> _fallbackRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'BYN': 3.25,
    'RUB': 90.0,
  };

  final SharedPreferences _prefs;
  Map<String, double> _rates = {};

  ExchangeRateService(this._prefs) {
    _loadCachedRates();
  }

  Map<String, double> get currentRates => _rates.isEmpty ? _fallbackRates : _rates;

  void _loadCachedRates() {
    final cached = _prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        _rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (e) {
        _rates = Map.from(_fallbackRates);
      }
    } else {
      _rates = Map.from(_fallbackRates);
    }
  }

  Future<void> fetchRates() async {
    try {
      // Try primary URL
      final response = await http
          .get(Uri.parse(_primaryUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rates'] != null) {
          final rates = data['rates'] as Map<String, dynamic>;
          _rates = {
            'USD': 1.0,
            'EUR': (rates['EUR'] as num?)?.toDouble() ?? _fallbackRates['EUR']!,
            'BYN': (rates['BYN'] as num?)?.toDouble() ?? _fallbackRates['BYN']!,
            'RUB': (rates['RUB'] as num?)?.toDouble() ?? _fallbackRates['RUB']!,
          };
          await _cacheRates();
          return;
        }
      }
    } catch (e) {
      // Primary failed, try fallback
    }

    try {
      // Try fallback URL
      final response = await http
          .get(Uri.parse(_fallbackUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['usd'] != null) {
          final rates = data['usd'] as Map<String, dynamic>;
          _rates = {
            'USD': 1.0,
            'EUR': (rates['eur'] as num?)?.toDouble() ?? _fallbackRates['EUR']!,
            'BYN': (rates['byn'] as num?)?.toDouble() ?? _fallbackRates['BYN']!,
            'RUB': (rates['rub'] as num?)?.toDouble() ?? _fallbackRates['RUB']!,
          };
          await _cacheRates();
          return;
        }
      }
    } catch (e) {
      // Both failed, use cached or fallback
    }

    // If both failed and no cache, use fallback
    if (_rates.isEmpty) {
      _rates = Map.from(_fallbackRates);
    }
  }

  Future<void> _cacheRates() async {
    final encoded = jsonEncode(_rates);
    await _prefs.setString(_cacheKey, encoded);
  }

  double convert(double amount, String from, String to) {
    if (from == to) return amount;

    final fromRate = currentRates[from] ?? 1.0;
    final toRate = currentRates[to] ?? 1.0;

    // Convert to USD first, then to target currency
    final amountInUsd = amount / fromRate;
    return amountInUsd * toRate;
  }
}
