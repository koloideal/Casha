import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/transaction.dart';
import '../dashboard/provider.dart';

final categoryExpenseProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(transactionsProvider)
      .where((t) => t.type == TransactionType.expense);

  final map = <String, double>{};
  for (final t in txs) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});
