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
      if (from == 1) {
        await migrator.createTable(accounts);
        await customStatement(
          'INSERT INTO accounts (name, is_main, currency, sort_order, created_at) '
          'VALUES (?, ?, ?, ?, ?)',
          ['main', 1, 'USD', 0, DateTime.now().millisecondsSinceEpoch],
        );
      }
      
      if (from == 2) {
        await customStatement(
          'ALTER TABLE accounts ADD COLUMN currency TEXT NOT NULL DEFAULT "USD"',
        );
      }
      
      if (from < 5) {
        try {
          final result = await customSelect(
            'PRAGMA table_info(transactions)',
          ).get();
          
          final hasAccountId = result.any((row) => row.data['name'] == 'account_id');
          
          if (!hasAccountId) {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN account_id INTEGER NOT NULL DEFAULT 1',
            );
          } 
        } catch (e) {
          print('Migration: Error adding account_id column: $e');
        }
      }
    },
  );

  Future<List<dynamic>> getAllTransactions() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

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

  Future<List<dynamic>> getTransactionsByType(String type) {
    return (select(transactions)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<dynamic>> getTransactionsByCategory(String category) {
    return (select(transactions)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

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

  Future<dynamic> getTransactionById(String id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Result<void>> insertTransaction(
    TransactionsCompanion transaction,
  ) async {
    return asyncResultOf(() async {
      await into(transactions).insert(transaction);
    });
  }

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

  Future<void> deleteAllTransactions() {
    return delete(transactions).go();
  }

  Future<List<dynamic>> getRecurringTransactions() {
    return (select(
      transactions,
    )..where((t) => t.recurrence.equals('none').not())).get();
  }

  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  Future<List<Category>> getCategoriesByType(String type) {
    return (select(categories)..where((c) => c.type.equals(type))).get();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Future<Budget?> getBudget(int month, int year) {
    return (select(budgets)
          ..where((b) => b.month.equals(month) & b.year.equals(year)))
        .getSingleOrNull();
  }

  Future<void> upsertBudget(BudgetsCompanion budget) {
    return into(budgets).insertOnConflictUpdate(budget);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  Future<ExchangeRate?> getExchangeRate(String from, String to) {
    return (select(exchangeRates)
          ..where((r) => r.fromCurrency.equals(from) & r.toCurrency.equals(to)))
        .getSingleOrNull();
  }

  Future<void> upsertExchangeRate(ExchangeRatesCompanion rate) {
    return into(exchangeRates).insertOnConflictUpdate(rate);
  }

  Future<List<ExchangeRate>> getAllExchangeRates() {
    return select(exchangeRates).get();
  }

  Future<int> deleteOldExchangeRates() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return (delete(
      exchangeRates,
    )..where((r) => r.updatedAt.isSmallerThanValue(yesterday))).go();
  }

  Future<double> getTotalBalance() async {
    final txs = await getAllTransactions();
    return txs.fold<double>(0.0, (sum, tx) {
      return tx.type == 'income' ? sum + tx.amount : sum - tx.amount;
    });
  }

  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final txs = await getTransactionsByDateRange(start, end);
    return txs
        .where((tx) => tx.type == 'income')
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final txs = await getTransactionsByDateRange(start, end);
    return txs
        .where((tx) => tx.type == 'expense')
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

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
