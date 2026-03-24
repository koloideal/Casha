import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../shared/models/account.dart' as model;

class AccountLimitException implements Exception {
  final String message;
  AccountLimitException(this.message);

  @override
  String toString() => 'AccountLimitException: $message';
}

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Stream<List<model.Account>> watchAll() {
    return (_db.select(_db.accounts)
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch()
        .asyncMap((rows) async {
      if (rows.isEmpty) {
        // Fallback: insert default account if none exists
        await _db.into(_db.accounts).insert(
              AccountsCompanion.insert(
                name: 'main',
                isMain: const Value(true),
                currency: const Value('USD'),
                sortOrder: const Value(0),
              ),
            );
        // Re-query after insert
        final newRows = await (_db.select(_db.accounts)
              ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
            .get();
        return newRows
            .map((row) => model.Account(
                  id: row.id,
                  name: row.name,
                  isMain: row.isMain,
                  sortOrder: row.sortOrder,
                  currency: row.currency,
                  createdAt: row.createdAt,
                ))
            .toList();
      }
      return rows
          .map((row) => model.Account(
                id: row.id,
                name: row.name,
                isMain: row.isMain,
                sortOrder: row.sortOrder,
                currency: row.currency,
                createdAt: row.createdAt,
              ))
          .toList();
    });
  }

  Future<List<model.Account>> getAll() async {
    try {
      var rows = await (_db.select(_db.accounts)
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
          .get();

      // Fallback: insert default account if none exists
      if (rows.isEmpty) {
        try {
          await _db.into(_db.accounts).insert(
                AccountsCompanion.insert(
                  name: 'main',
                  isMain: const Value(true),
                  currency: const Value('USD'),
                  sortOrder: const Value(0),
                ),
              );
        } catch (e) {
          // Ignore if already exists
        }
        // Re-query after insert
        rows = await (_db.select(_db.accounts)
              ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
            .get();
      }

      return rows
          .map((row) => model.Account(
                id: row.id,
                name: row.name,
                isMain: row.isMain,
                sortOrder: row.sortOrder,
                currency: row.currency,
                createdAt: row.createdAt,
              ))
          .toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<model.Account> getMain() async {
    final row = await (_db.select(_db.accounts)
          ..where((a) => a.isMain.equals(true)))
        .getSingleOrNull();

    if (row != null) {
      return model.Account(
        id: row.id,
        name: row.name,
        isMain: row.isMain,
        sortOrder: row.sortOrder,
        currency: row.currency,
        createdAt: row.createdAt,
      );
    }

    // Fallback if no main account is found
    final all = await getAll();
    if (all.isNotEmpty) return all.first;

    // Absolute fallback: create and return a default account
    try {
      await _db.into(_db.accounts).insert(
            AccountsCompanion.insert(
              name: 'main',
              isMain: const Value(true),
              currency: const Value('USD'),
              sortOrder: const Value(0),
            ),
          );
      
      // Query the newly created account
      final newRow = await (_db.select(_db.accounts)
            ..where((a) => a.isMain.equals(true)))
          .getSingleOrNull();
      
      if (newRow != null) {
        return model.Account(
          id: newRow.id,
          name: newRow.name,
          isMain: newRow.isMain,
          sortOrder: newRow.sortOrder,
          currency: newRow.currency,
          createdAt: newRow.createdAt,
        );
      }
    } catch (_) {
      // Ignore insert errors
    }

    // Final fallback to prevent crashes
    return model.Account(
      id: 1,
      name: 'main',
      isMain: true,
      sortOrder: 0,
      currency: 'USD',
      createdAt: DateTime.now(),
    );
  }

  Future<void> update(model.Account account) async {
    await _db.updateAccount(AccountsCompanion(
      id: Value(account.id),
      name: Value(account.name),
      isMain: Value(account.isMain),
      sortOrder: Value(account.sortOrder),
      currency: Value(account.currency),
      createdAt: Value(account.createdAt),
    ));
  }

  Future<int> add(model.Account account) async {
    return await _db.into(_db.accounts).insert(
      AccountsCompanion.insert(
        name: account.name,
        isMain: Value(account.isMain),
        sortOrder: Value(account.sortOrder),
        currency: Value(account.currency),
        createdAt: Value(account.createdAt),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
  }
}
