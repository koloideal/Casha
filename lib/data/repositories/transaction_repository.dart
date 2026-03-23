import 'package:drift/drift.dart';
import '../../core/utils/result.dart';
import '../../shared/models/transaction.dart' as model;
import '../database/app_database.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  /// Get all transactions
  Future<Result<List<model.Transaction>>> getAll() async {
    return asyncResultOf(() async {
      final transactions = await _db.getAllTransactions();
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  /// Get transactions by date range
  Future<Result<List<model.Transaction>>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return asyncResultOf(() async {
      final transactions = await _db.getTransactionsByDateRange(start, end);
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  /// Get transactions by type
  Future<Result<List<model.Transaction>>> getByType(
    model.TransactionType type,
  ) async {
    return asyncResultOf(() async {
      final transactions = await _db.getTransactionsByType(type.name);
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  /// Search transactions
  Future<Result<List<model.Transaction>>> search(String query) async {
    return asyncResultOf(() async {
      final transactions = await _db.searchTransactions(query);
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  /// Get transaction by ID
  Future<Result<model.Transaction?>> getById(String id) async {
    return asyncResultOf(() async {
      final transaction = await _db.getTransactionById(id);
      return transaction != null ? _toModel(transaction) : null;
    });
  }

  /// Add transaction
  Future<Result<void>> add(model.Transaction transaction) async {
    return asyncResultOf(() async {
      print('--- SAVING TRANSACTION: START ---');
      print('Transaction data: ID=${transaction.id}, Amount=${transaction.amount}, AccId=${transaction.accountId}');
      print('Category=${transaction.category}, Type=${transaction.type.name}');
      print('Date=${transaction.date}, Currency=${transaction.currencyCode}');
      
      final companion = _toCompanion(transaction);
      print('Companion created successfully');
      print('Companion: $companion');
      
      final result = await _db.insertTransaction(companion);
      print('DB Insert finished. Result Success: ${result.isSuccess}');

      if (result.isFailure) {
        print('!!! DB INSERT FAILED: ${result.errorOrNull}');
        throw Exception(result.errorOrNull);
      }
      
      print('--- SAVING TRANSACTION: END (SUCCESS) ---');
    });
  }

  /// Update transaction
  Future<Result<void>> update(model.Transaction transaction) async {
    return asyncResultOf(() async {
      final dbTransaction = _toDbModel(transaction);
      final result = await _db.updateTransaction(dbTransaction);

      if (result.isFailure) {
        throw Exception(result.errorOrNull);
      }
    });
  }

  /// Delete transaction
  Future<Result<void>> delete(String id) async {
    return _db.deleteTransaction(id);
  }

  /// Delete all transactions
  Future<Result<void>> deleteAll() async {
    return asyncResultOf(() async {
      await _db.deleteAllTransactions();
    });
  }

  /// Get recurring transactions
  Future<Result<List<model.Transaction>>> getRecurring() async {
    return asyncResultOf(() async {
      final transactions = await _db.getRecurringTransactions();
      return transactions.map<model.Transaction>(_toModel).toList();
    });
  }

  /// Get total balance
  Future<Result<double>> getTotalBalance() async {
    return asyncResultOf(() async {
      return await _db.getTotalBalance();
    });
  }

  /// Get total income for date range
  Future<Result<double>> getTotalIncome(DateTime start, DateTime end) async {
    return asyncResultOf(() async {
      return await _db.getTotalIncome(start, end);
    });
  }

  /// Get total expense for date range
  Future<Result<double>> getTotalExpense(DateTime start, DateTime end) async {
    return asyncResultOf(() async {
      return await _db.getTotalExpense(start, end);
    });
  }

  /// Get category totals
  Future<Result<Map<String, double>>> getCategoryTotals(
    DateTime start,
    DateTime end,
    model.TransactionType type,
  ) async {
    return asyncResultOf(() async {
      return await _db.getCategoryTotals(start, end, type.name);
    });
  }

  // ============================================================================
  // CONVERTERS
  // ============================================================================

  /// Convert database model to app model
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

  /// Convert app model to database model
  dynamic _toDbModel(model.Transaction transaction) {
    // This will be replaced with proper TransactionData after code generation
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

  /// Convert app model to companion for insert
  TransactionsCompanion _toCompanion(model.Transaction transaction) {
    try {
      print('_toCompanion: Creating companion for transaction ${transaction.id}');
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
      print('_toCompanion: Companion created successfully');
      return companion;
    } catch (e, stack) {
      print('!!! _toCompanion FAILED !!!');
      print('Error: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  /// Parse recurrence type
  model.RecurrenceType _parseRecurrence(String recurrence) {
    return model.RecurrenceType.values.firstWhere(
      (e) => e.name == recurrence,
      orElse: () => model.RecurrenceType.none,
    );
  }
}
