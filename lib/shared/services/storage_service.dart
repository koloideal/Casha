import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const _transactionsKey = 'transactions';
  static const _budgetKey = 'monthly_budget';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  List<Transaction> loadTransactions() {
    final raw = _prefs.getString(_transactionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _prefs.setString(_transactionsKey, encoded);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final list = loadTransactions();
    list.add(transaction);
    await saveTransactions(list);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final list = loadTransactions();
    final index = list.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      list[index] = transaction;
      await saveTransactions(list);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final list = loadTransactions()..removeWhere((t) => t.id == id);
    await saveTransactions(list);
  }

  double? loadBudget() {
    return _prefs.getDouble(_budgetKey);
  }

  Future<void> saveBudget(double? budget) async {
    if (budget == null) {
      await _prefs.remove(_budgetKey);
    } else {
      await _prefs.setDouble(_budgetKey, budget);
    }
  }
}
