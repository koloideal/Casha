import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/transaction.dart';
import '../../shared/services/storage_service.dart';
import '../settings/provider.dart';

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

// Converted balance providers (convert all transactions to selected currency)
final totalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return txs.fold(0.0, (sum, t) {
    final converted = exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
    return t.type == TransactionType.income ? sum + converted : sum - converted;
  });
});

final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).where((t) => t.type == TransactionType.income);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return txs.fold(0.0, (sum, t) {
    return sum + exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
  });
});

final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).where((t) => t.type == TransactionType.expense);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return txs.fold(0.0, (sum, t) {
    return sum + exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
  });
});

final currentMonthExpenseProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final txs = ref.watch(transactionsProvider).where((t) =>
      t.type == TransactionType.expense &&
      t.date.year == now.year &&
      t.date.month == now.month);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return txs.fold(0.0, (sum, t) {
    return sum + exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
  });
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
