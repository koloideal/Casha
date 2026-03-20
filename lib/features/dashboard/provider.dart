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

  Future<void> update(Transaction transaction) async {
    await _storage.updateTransaction(transaction);
    state = _storage.loadTransactions();
  }

  Future<void> delete(String id) async {
    await _storage.deleteTransaction(id);
    state = _storage.loadTransactions();
  }

  void restore(Transaction transaction) {
    state = [...state, transaction];
    _storage.addTransaction(transaction);
  }
}

// Search and filter state
final searchQueryProvider = StateProvider<String>((ref) => '');

enum TransactionFilter { all, income, expense }

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.all);

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

final currentMonthExpenseProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return ref
      .watch(transactionsProvider)
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txs = ref.watch(transactionsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filter = ref.watch(transactionFilterProvider);

  var filtered = txs;

  // Apply type filter
  if (filter == TransactionFilter.income) {
    filtered = filtered.where((t) => t.type == TransactionType.income).toList();
  } else if (filter == TransactionFilter.expense) {
    filtered = filtered.where((t) => t.type == TransactionType.expense).toList();
  }

  // Apply search query
  if (query.isNotEmpty) {
    filtered = filtered.where((t) {
      final matchesCategory = t.category.toLowerCase().contains(query);
      final matchesNote = t.note?.toLowerCase().contains(query) ?? false;
      return matchesCategory || matchesNote;
    }).toList();
  }

  // Sort by date descending
  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(filteredTransactionsProvider).take(20).toList();
});
