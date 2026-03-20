import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

const _uuid = Uuid();

class StorageService {
  static const _transactionsKey = 'transactions';
  static const _budgetKey = 'monthly_budget';
  static const _currencyKey = 'currency_symbol';
  static const _themeKey = 'is_dark_mode';

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

  String loadCurrency() {
    return _prefs.getString(_currencyKey) ?? '\$';
  }

  Future<void> saveCurrency(String symbol) async {
    await _prefs.setString(_currencyKey, symbol);
  }

  bool loadThemeMode() {
    return _prefs.getBool(_themeKey) ?? true;
  }

  Future<void> saveThemeMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  Future<void> processRecurringTransactions() async {
    final transactions = loadTransactions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool hasChanges = false;

    for (final tx in transactions) {
      if (tx.recurrence == RecurrenceType.none) continue;

      final lastOccurrence = tx.lastOccurrence ?? tx.date;
      final lastDate = DateTime(
        lastOccurrence.year,
        lastOccurrence.month,
        lastOccurrence.day,
      );

      bool shouldCreate = false;

      switch (tx.recurrence) {
        case RecurrenceType.daily:
          shouldCreate = today.isAfter(lastDate);
          break;
        case RecurrenceType.weekly:
          final daysDiff = today.difference(lastDate).inDays;
          shouldCreate = daysDiff >= 7;
          break;
        case RecurrenceType.monthly:
          shouldCreate = (today.year > lastDate.year ||
                  (today.year == lastDate.year &&
                      today.month > lastDate.month)) &&
              today.day >= lastDate.day;
          break;
        case RecurrenceType.none:
          break;
      }

      if (shouldCreate) {
        final newTx = Transaction(
          id: _uuid.v4(),
          amount: tx.amount,
          category: tx.category,
          type: tx.type,
          date: today,
          note: tx.note,
          recurrence: tx.recurrence,
          lastOccurrence: today,
        );
        transactions.add(newTx);

        final index = transactions.indexWhere((t) => t.id == tx.id);
        if (index != -1) {
          transactions[index] = tx.copyWith(lastOccurrence: today);
        }

        hasChanges = true;
      }
    }

    if (hasChanges) {
      await saveTransactions(transactions);
    }
  }
}
