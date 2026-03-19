import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/transaction.dart';
import '../../shared/services/storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TransactionsNotifier(storage);
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final StorageService _storage;

  TransactionsNotifier(this._storage) : super(_storage.loadTransactions());

  Future<void> add(Transaction transaction) async {
    await _storage.addTransaction(transaction);
    state = _storage.loadTransactions();
  }

  Future<void> delete(String id) async {
    await _storage.deleteTransaction(id);
    state = _storage.loadTransactions();
  }
}

// Derived providers
final totalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider);
  return txs.fold(0.0, (sum, t) {
    return t.type == TransactionType.income ? sum + t.amount : sum - t.amount;
  });
});

final totalIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(transactionsProvider)
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  return ref
      .watch(transactionsProvider)
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txs = List<Transaction>.from(ref.watch(transactionsProvider));
  txs.sort((a, b) => b.date.compareTo(a.date));
  return txs.take(20).toList();
});
