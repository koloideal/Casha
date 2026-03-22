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
                name: 'Main',
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

      print('AccountRepository.getAll(): rows.length = ${rows.length}');

      // Fallback: insert default account if none exists
      if (rows.isEmpty) {
        print('AccountRepository.getAll(): inserting default account');
        try {
          await _db.into(_db.accounts).insert(
                AccountsCompanion.insert(
                  name: 'Main',
                  isMain: const Value(true),
                  currency: const Value('USD'),
                  sortOrder: const Value(0),
                ),
              );
          print('AccountRepository.getAll(): default account inserted');
        } catch (e) {
          print('AccountRepository.getAll(): insert error: $e');
        }
        // Re-query after insert
        rows = await (_db.select(_db.accounts)
              ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
            .get();
        print('AccountRepository.getAll(): after insert, rows.length = ${rows.length}');
      }

      final accounts = rows
          .map((row) => model.Account(
                id: row.id,
                name: row.name,
                isMain: row.isMain,
                sortOrder: row.sortOrder,
                currency: row.currency,
                createdAt: row.createdAt,
              ))
          .toList();
      
      print('AccountRepository.getAll(): returning ${accounts.length} accounts');
      return accounts;
    } catch (e, stack) {
      print('AccountRepository.getAll(): error: $e');
      print('Stack: $stack');
      // Return empty list on error
      return [];
    }
  }

  Future<model.Account> getMain() async {
    final row = await (_db.select(_db.accounts)
          ..where((a) => a.isMain.equals(true)))
        .getSingle();

    return model.Account(
      id: row.id,
      name: row.name,
      isMain: row.isMain,
      sortOrder: row.sortOrder,
      currency: row.currency,
      createdAt: row.createdAt,
    );
  }
}
