import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/result.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Transactions, Categories, Budgets, ExchangeRates, Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      print('--- DATABASE MIGRATION: from=$from to=$to ---');
      
      if (from == 1) {
        print('Migration: Creating accounts table');
        await migrator.createTable(accounts);
        await customStatement(
          'INSERT INTO accounts (name, is_main, currency, sort_order, created_at) '
          'VALUES (?, ?, ?, ?, ?)',
          ['main', 1, 'USD', 0, DateTime.now().millisecondsSinceEpoch],
        );
      }
      
      if (from == 2) {
        print('Migration: Adding currency column to accounts');
        await customStatement(
          'ALTER TABLE accounts ADD COLUMN currency TEXT NOT NULL DEFAULT "USD"',
        );
      }
      
      // Add account_id column to transactions if upgrading from version < 5
      if (from < 5) {
        print('Migration: Adding account_id column to transactions');
        try {
          // Check if column exists first
          final result = await customSelect(
            'PRAGMA table_info(transactions)',
          ).get();
          
          final hasAccountId = result.any((row) => row.data['name'] == 'account_id');
          
          if (!hasAccountId) {
            print('Migration: account_id column does not exist, adding it now');
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN account_id INTEGER NOT NULL DEFAULT 1',
            );
            print('Migration: account_id column added successfully');
          } else {
            print('Migration: account_id column already exists, skipping');
          }
        } catch (e) {
          print('Migration: Error adding account_id column: $e');
          // If the column already exists, this will fail, which is fine
        }
      }
      
      print('--- DATABASE MIGRATION: COMPLETE ---');
    },
  );

  // ============================================================================
  // TRANSACTIONS
  // ============================================================================

  /// Get all transactions ordered by date descending
  Future<List<dynamic>> getAllTransactions() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  /// Get transactions by date range
  Future<List<dynamic>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(start))
          ..where((t) => t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions by type
  Future<List<dynamic>> getTransactionsByType(String type) {
    return (select(transactions)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions by category
  Future<List<dynamic>> getTransactionsByCategory(String category) {
    return (select(transactions)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Search transactions by note or category
  Future<List<dynamic>> searchTransactions(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(transactions)
          ..where(
            (t) =>
                t.category.lower().like('%$lowerQuery%') |
                t.note.lower().like('%$lowerQuery%'),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transaction by ID
  Future<dynamic> getTransactionById(String id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert transaction
  Future<Result<void>> insertTransaction(
    TransactionsCompanion transaction,
  ) async {
    return asyncResultOf(() async {
      await into(transactions).insert(transaction);
    });
  }

  /// Update transaction
  Future<Result<void>> updateTransaction(dynamic transaction) async {
    return asyncResultOf(() async {
      final companion = transaction as TransactionsCompanion;
      final updated = await (update(
        transactions,
      )..where((t) => t.id.equals(companion.id.value))).write(companion);

      if (updated == 0) {
        throw Exception('Transaction not found');
      }
    });
  }

  /// Delete transaction
  Future<Result<void>> deleteTransaction(String id) async {
    return asyncResultOf(() async {
      final deleted = await (delete(
        transactions,
      )..where((t) => t.id.equals(id))).go();

      if (deleted == 0) {
        throw Exception('Transaction not found');
      }
    });
  }

  /// Delete all transactions
  Future<void> deleteAllTransactions() {
    return delete(transactions).go();
  }

  /// Get recurring transactions that need processing
  Future<List<dynamic>> getRecurringTransactions() {
    return (select(
      transactions,
    )..where((t) => t.recurrence.equals('none').not())).get();
  }

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  /// Get all categories
  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  /// Get categories by type
  Future<List<Category>> getCategoriesByType(String type) {
    return (select(categories)..where((c) => c.type.equals(type))).get();
  }

  /// Insert category
  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Update category
  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  /// Delete category
  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  // ============================================================================
  // BUDGETS
  // ============================================================================

  /// Get budget for month/year
  Future<Budget?> getBudget(int month, int year) {
    return (select(budgets)
          ..where((b) => b.month.equals(month) & b.year.equals(year)))
        .getSingleOrNull();
  }

  /// Insert or update budget
  Future<void> upsertBudget(BudgetsCompanion budget) {
    return into(budgets).insertOnConflictUpdate(budget);
  }

  /// Delete budget
  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  // ============================================================================
  // EXCHANGE RATES
  // ============================================================================

  /// Get exchange rate
  Future<ExchangeRate?> getExchangeRate(String from, String to) {
    return (select(exchangeRates)
          ..where((r) => r.fromCurrency.equals(from) & r.toCurrency.equals(to)))
        .getSingleOrNull();
  }

  /// Insert or update exchange rate
  Future<void> upsertExchangeRate(ExchangeRatesCompanion rate) {
    return into(exchangeRates).insertOnConflictUpdate(rate);
  }

  /// Get all exchange rates
  Future<List<ExchangeRate>> getAllExchangeRates() {
    return select(exchangeRates).get();
  }

  /// Delete old exchange rates (older than 24 hours)
  Future<int> deleteOldExchangeRates() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return (delete(
      exchangeRates,
    )..where((r) => r.updatedAt.isSmallerThanValue(yesterday))).go();
  }

  // ============================================================================
  // STATISTICS & AGGREGATIONS
  // ============================================================================

  /// Get total balance
  Future<double> getTotalBalance() async {
    final txs = await getAllTransactions();
    return txs.fold<double>(0.0, (sum, tx) {
      return tx.type == 'income' ? sum + tx.amount : sum - tx.amount;
    });
  }

  /// Get total income for date range
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final txs = await getTransactionsByDateRange(start, end);
    return txs
        .where((tx) => tx.type == 'income')
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Get total expense for date range
  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final txs = await getTransactionsByDateRange(start, end);
    return txs
        .where((tx) => tx.type == 'expense')
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Get category totals for date range
  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
    String type,
  ) async {
    final txs = await getTransactionsByDateRange(start, end);
    final filtered = txs.where((tx) => tx.type == type);

    final Map<String, double> totals = {};
    for (final tx in filtered) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }

    return totals;
  }

  // ============================================================================
  // ACCOUNTS
  // ============================================================================

  /// Update an account
  Future<void> updateAccount(AccountsCompanion account) async {
    await update(accounts).replace(account);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'casha.db'));
    return NativeDatabase(file);
  });
}
