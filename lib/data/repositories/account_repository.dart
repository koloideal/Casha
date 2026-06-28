import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../shared/models/account.dart' as model;
import '../../shared/feature_flags/feature_flags.dart';

class FeatureLimitException implements Exception {
  final String message;
  FeatureLimitException(this.message);

  @override
  String toString() => 'FeatureLimitException: $message';
}

class AccountRepository {
  final AppDatabase _db;
  final FeatureFlags _featureFlags;

  AccountRepository(this._db, this._featureFlags);

  Stream<List<model.Account>> watchAll() {
    return (_db.select(_db.accounts)
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch()
        .asyncMap((rows) async {
      if (rows.isEmpty) {
        await _db.into(_db.accounts).insert(
              AccountsCompanion.insert(
                name: 'main',
                isMain: const Value(true),
                currency: const Value('USD'),
                sortOrder: const Value(0),
              ),
            );
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

    final all = await getAll();
    if (all.isNotEmpty) return all.first;

    try {
      await _db.into(_db.accounts).insert(
            AccountsCompanion.insert(
              name: 'main',
              isMain: const Value(true),
              currency: const Value('USD'),
              sortOrder: const Value(0),
            ),
          );
      
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
    final existing = await getAll();
    final nonMainCount = existing.where((a) => !a.isMain).length;
    if (nonMainCount >= _featureFlags.maxAccounts) {
      throw FeatureLimitException('Account limit reached (${_featureFlags.maxAccounts})');
    }
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
