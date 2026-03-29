import 'package:drift/drift.dart';
import '../../core/utils/result.dart';
import '../../shared/models/transaction.dart' as model;
import '../database/app_database.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  Future<Result<List<model.Transaction>>> getAll() async {
    return asyncResultOf(() async {
      final transactions = await _db.getAllTransactions();
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  Future<Result<List<model.Transaction>>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return asyncResultOf(() async {
      final transactions = await _db.getTransactionsByDateRange(start, end);
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  Future<Result<List<model.Transaction>>> getByType(
    model.TransactionType type,
  ) async {
    return asyncResultOf(() async {
      final transactions = await _db.getTransactionsByType(type.name);
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  Future<Result<List<model.Transaction>>> search(String query) async {
    return asyncResultOf(() async {
      final transactions = await _db.searchTransactions(query);
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  Future<Result<model.Transaction?>> getById(String id) async {
    return asyncResultOf(() async {
      final transaction = await _db.getTransactionById(id);
      return transaction != null ? _toModel(transaction) : null;
    });
  }

  Future<Result<void>> add(model.Transaction transaction) async {
    return asyncResultOf(() async {
      final companion = _toCompanion(transaction);
      final result = await _db.insertTransaction(companion);

      if (result.isFailure) {
        throw Exception(result.errorOrNull);
      }
    });
  }

  Future<Result<void>> update(model.Transaction transaction) async {
    return asyncResultOf(() async {
      final dbTransaction = _toDbModel(transaction);
      final result = await _db.updateTransaction(dbTransaction);

      if (result.isFailure) {
        throw Exception(result.errorOrNull);
      }
    });
  }

  Future<Result<void>> delete(String id) async {
    return _db.deleteTransaction(id);
  }

  Future<Result<void>> deleteAll() async {
    return asyncResultOf(() async {
      await _db.deleteAllTransactions();
    });
  }

  Future<Result<List<model.Transaction>>> getRecurring() async {
    return asyncResultOf(() async {
      final transactions = await _db.getRecurringTransactions();
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  Future<Result<double>> getTotalBalance() async {
    return asyncResultOf(() async {
      return await _db.getTotalBalance();
    });
  }

  Future<Result<double>> getTotalIncome(DateTime start, DateTime end) async {
    return asyncResultOf(() async {
      return await _db.getTotalIncome(start, end);
    });
  }

  Future<Result<double>> getTotalExpense(DateTime start, DateTime end) async {
    return asyncResultOf(() async {
      return await _db.getTotalExpense(start, end);
    });
  }

  Future<Result<Map<String, double>>> getCategoryTotals(
    DateTime start,
    DateTime end,
    model.TransactionType type,
  ) async {
    return asyncResultOf(() async {
      return await _db.getCategoryTotals(start, end, type.name);
    });
  }

  model.Transaction _toModel(dynamic dbTransaction) {
    return model.Transaction(
      id: dbTransaction.id as String,
      amount: dbTransaction.amount as double,
      category: dbTransaction.category as String,
      type: (dbTransaction.type as String) == 'income'
          ? model.TransactionType.income
          : model.TransactionType.expense,
      date: dbTransaction.date as DateTime,
      note: dbTransaction.note as String?,
      recurrence: _parseRecurrence(dbTransaction.recurrence as String),
      lastOccurrence: dbTransaction.lastOccurrence as DateTime?,
      currency: dbTransaction.currency as String,
      currencyCode: dbTransaction.currencyCode as String,
      accountId: dbTransaction.accountId as int,
    );
  }

  dynamic _toDbModel(model.Transaction transaction) {
    return TransactionsCompanion(
      id: Value(transaction.id),
      amount: Value(transaction.amount),
      category: Value(transaction.category),
      type: Value(transaction.type.name),
      date: Value(transaction.date),
      note: Value(transaction.note),
      recurrence: Value(transaction.recurrence.name),
      lastOccurrence: Value(transaction.lastOccurrence),
      currency: Value(transaction.currency),
      currencyCode: Value(transaction.currencyCode),
      accountId: Value(transaction.accountId),
      createdAt: Value(DateTime.now()),
    );
  }

  TransactionsCompanion _toCompanion(model.Transaction transaction) {
    try {
      final companion = TransactionsCompanion(
        id: Value(transaction.id),
        amount: Value(transaction.amount),
        category: Value(transaction.category),
        type: Value(transaction.type.name),
        date: Value(transaction.date),
        note: Value(transaction.note),
        recurrence: Value(transaction.recurrence.name),
        lastOccurrence: Value(transaction.lastOccurrence),
        currency: Value(transaction.currency),
        currencyCode: Value(transaction.currencyCode),
        accountId: Value(transaction.accountId),
      );
      return companion;
    } catch (e, _) {
      rethrow;
    }
  }

  model.RecurrenceType _parseRecurrence(String recurrence) {
    return model.RecurrenceType.values.firstWhere(
      (e) => e.name == recurrence,
      orElse: () => model.RecurrenceType.none,
    );
  }
}
