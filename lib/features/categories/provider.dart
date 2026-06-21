import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/transaction.dart';
import '../dashboard/provider.dart';
import '../settings/provider.dart';

String _statsTargetCurrency(Ref ref) {
  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final globalCurrency = ref.watch(currencyProvider).code;

  if (index > 0) {
    final accounts = accountsAsync.value ?? [];
    if (index <= accounts.length) {
      return accounts[index - 1].currency;
    }
  }

  return globalCurrency;
}

CurrencyInfo _statsCurrencyInfo(Ref ref) {
  final code = _statsTargetCurrency(ref);
  return CurrencyInfo(currencyMap[code]?.symbol ?? '\$', code);
}

List<Transaction> _statsScopedTransactions(Ref ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final timeFilter = ref.watch(timeFilterProvider);
  var filtered = txs.where((t) => t.category != 'Transfer');

  if (timeFilter == TimeFilter.lastMonth) {
    final now = DateTime.now();
    filtered = filtered.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );
  }

  return filtered.toList();
}

double _convertAmount(Ref ref, Transaction t) {
  final exchange = ref.watch(exchangeRateServiceProvider);
  return exchange.convert(
    t.amount,
    t.currencyCode,
    _statsTargetCurrency(ref),
  );
}

final statsCurrencyProvider = Provider<CurrencyInfo>((ref) {
  return _statsCurrencyInfo(ref);
});

final statsIncomeTotalProvider = Provider<double>((ref) {
  return _statsScopedTransactions(ref)
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + _convertAmount(ref, t));
});

final statsExpenseTotalProvider = Provider<double>((ref) {
  return _statsScopedTransactions(ref)
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + _convertAmount(ref, t));
});

final categoryExpenseProvider = Provider<Map<String, double>>((ref) {
  final map = <String, double>{};
  for (final t in _statsScopedTransactions(ref)) {
    if (t.type != TransactionType.expense) continue;
    map[t.category] = (map[t.category] ?? 0) + _convertAmount(ref, t);
  }
  return map;
});

final categoryIncomeProvider = Provider<Map<String, double>>((ref) {
  final map = <String, double>{};
  for (final t in _statsScopedTransactions(ref)) {
    if (t.type != TransactionType.income) continue;
    map[t.category] = (map[t.category] ?? 0) + _convertAmount(ref, t);
  }
  return map;
});

final monthlyBreakdownProvider = Provider<List<MonthlyData>>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final exchange = ref.watch(exchangeRateServiceProvider);
  final target = _statsTargetCurrency(ref);
  final now = DateTime.now();
  final months = <MonthlyData>[];

  for (var i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final total = txs
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.category != 'Transfer' &&
              t.date.year == month.year &&
              t.date.month == month.month,
        )
        .fold(0.0, (sum, t) {
          return sum + exchange.convert(t.amount, t.currencyCode, target);
        });
    months.add(MonthlyData(month: month, amount: total));
  }

  return months;
});

final monthlyIncomeBreakdownProvider = Provider<List<MonthlyData>>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final exchange = ref.watch(exchangeRateServiceProvider);
  final target = _statsTargetCurrency(ref);
  final now = DateTime.now();
  final months = <MonthlyData>[];

  for (var i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final total = txs
        .where(
          (t) =>
              t.type == TransactionType.income &&
              t.category != 'Transfer' &&
              t.date.year == month.year &&
              t.date.month == month.month,
        )
        .fold(0.0, (sum, t) {
          return sum + exchange.convert(t.amount, t.currencyCode, target);
        });
    months.add(MonthlyData(month: month, amount: total));
  }

  return months;
});

class MonthlyData {
  final DateTime month;
  final double amount;

  MonthlyData({required this.month, required this.amount});
}
