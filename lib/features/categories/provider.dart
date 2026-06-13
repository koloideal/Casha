import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/transaction.dart';
import '../dashboard/provider.dart';

final categoryExpenseProvider = Provider<Map<String, double>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.value ?? [];
  final filtered = txs.where((t) => t.type == TransactionType.expense);

  final map = <String, double>{};
  for (final t in filtered) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

final categoryIncomeProvider = Provider<Map<String, double>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.value ?? [];
  final filtered = txs.where((t) => t.type == TransactionType.income);

  final map = <String, double>{};
  for (final t in filtered) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

final monthlyBreakdownProvider = Provider<List<MonthlyData>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.value ?? [];
  final filtered = txs.where((t) => t.type == TransactionType.expense);

  final now = DateTime.now();
  final months = <MonthlyData>[];

  for (var i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final total = filtered
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .fold(0.0, (sum, t) => sum + t.amount);
    months.add(MonthlyData(month: month, amount: total));
  }

  return months;
});

class MonthlyData {
  final DateTime month;
  final double amount;

  MonthlyData({required this.month, required this.amount});
}
