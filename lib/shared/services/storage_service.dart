import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const _key = 'transactions';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  List<Transaction> loadTransactions() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final list = loadTransactions();
    list.add(transaction);
    await saveTransactions(list);
  }

  Future<void> deleteTransaction(String id) async {
    final list = loadTransactions()..removeWhere((t) => t.id == id);
    await saveTransactions(list);
  }
}
