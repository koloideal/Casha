import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/result.dart';
import '../models/transaction.dart';

const _uuid = Uuid();

class StorageService {
  static const _transactionsKey = 'transactions';
  static const _currencyKey = 'currency_symbol';
  static const _themeKey = 'is_dark_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Result<List<Transaction>> loadTransactions() {
    return resultOf(() {
      final raw = _prefs.getString(_transactionsKey);
      if (raw == null) return <Transaction>[];

      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  List<Transaction> loadTransactionsUnsafe() {
    final result = loadTransactions();
    return result.getOrDefault([]);
  }

  Future<Result<void>> saveTransactions(List<Transaction> transactions) async {
    return asyncResultOf(() async {
      final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
      await _prefs.setString(_transactionsKey, encoded);
    });
  }

  Future<Result<void>> addTransaction(Transaction transaction) async {
    return asyncResultOf(() async {
      final listResult = loadTransactions();
      final list = listResult.getOrDefault([]);
      list.add(transaction);

      final saveResult = await saveTransactions(list);
      if (saveResult.isFailure) {
        throw Exception(saveResult.errorOrNull);
      }
    });
  }

  Future<Result<void>> updateTransaction(Transaction transaction) async {
    return asyncResultOf(() async {
      final listResult = loadTransactions();
      final list = listResult.getOrDefault([]);

      final index = list.indexWhere((t) => t.id == transaction.id);
      if (index == -1) {
        throw Exception('Transaction not found: ${transaction.id}');
      }

      list[index] = transaction;
      final saveResult = await saveTransactions(list);
      if (saveResult.isFailure) {
        throw Exception(saveResult.errorOrNull);
      }
    });
  }

  Future<Result<void>> deleteTransaction(String id) async {
    return asyncResultOf(() async {
      final listResult = loadTransactions();
      final list = listResult.getOrDefault([]);

      final initialLength = list.length;
      list.removeWhere((t) => t.id == id);

      if (list.length == initialLength) {
        throw Exception('Transaction not found: $id');
      }

      final saveResult = await saveTransactions(list);
      if (saveResult.isFailure) {
        throw Exception(saveResult.errorOrNull);
      }
    });
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
    final transactionsResult = loadTransactions();
    final transactions = transactionsResult.getOrDefault([]);
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
          shouldCreate =
              (today.year > lastDate.year ||
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
          accountId: tx.accountId,
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

  Future<Result<int>> processRecurringTransactionsWithResult() async {
    return asyncResultOf(() async {
      final transactionsResult = loadTransactions();
      final transactions = transactionsResult.getOrDefault([]);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int createdCount = 0;

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
            shouldCreate =
                (today.year > lastDate.year ||
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
            currency: tx.currency,
            currencyCode: tx.currencyCode,
            accountId: tx.accountId,
          );
          transactions.add(newTx);

          final index = transactions.indexWhere((t) => t.id == tx.id);
          if (index != -1) {
            transactions[index] = tx.copyWith(lastOccurrence: today);
          }

          createdCount++;
        }
      }

      if (createdCount > 0) {
        final saveResult = await saveTransactions(transactions);
        if (saveResult.isFailure) {
          throw Exception('Failed to save recurring transactions');
        }
      }

      return createdCount;
    });
  }
}
