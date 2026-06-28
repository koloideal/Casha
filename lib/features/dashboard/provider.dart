import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/card_color_service.dart';
import '../../core/utils/result.dart';
import '../../data/database/app_database.dart' as db;
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../shared/feature_flags/feature_flags_provider.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/account.dart';
import '../../shared/services/storage_service.dart';
import '../settings/provider.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main');
});

final appDatabaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionRepository(db);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final flags = ref.watch(featureFlagsProvider);
  return AccountRepository(db, flags);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
      TransactionsNotifier.new,
    );

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    final result = await repository.getAll();

    if (result.isSuccess) {
      return result.dataOrNull!;
    } else {
      throw result.errorOrNull!;
    }
  }

  Future<Result<void>> add(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.add(transaction);

    if (result.isSuccess) {
      ref.invalidateSelf();
    }

    return result;
  }

  Future<Result<void>> updateTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.update(transaction);

    if (result.isSuccess) {
      ref.invalidateSelf();
    }

    return result;
  }

  Future<Result<void>> delete(String id) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.delete(id);

    if (result.isSuccess) {
      ref.invalidateSelf();
    }

    return result;
  }

  Future<void> restore(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    await repository.add(transaction);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    final repository = ref.read(transactionRepositoryProvider);
    await repository.deleteAll();
    state = const AsyncValue.data([]);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final transferPairsProvider = Provider<Map<String, Transaction>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.value ?? [];
  final transfers = txs.where((t) => t.category == 'Transfer').toList();
  final Map<String, Transaction> pairs = {};

  for (final tx in transfers) {
    if (pairs.containsKey(tx.id)) continue;
    final counterpart = transfers.firstWhereOrNull(
      (other) =>
          other.id != tx.id &&
          other.type != tx.type &&
          other.amount == tx.amount &&
          other.date.year == tx.date.year &&
          other.date.month == tx.date.month &&
          other.date.day == tx.date.day &&
          other.date.hour == tx.date.hour &&
          other.date.minute == tx.date.minute &&
          other.note == tx.note,
    );
    if (counterpart != null) {
      pairs[tx.id] = counterpart;
      pairs[counterpart.id] = tx;
    }
  }
  return pairs;
});

final searchQueryProvider = NotifierProvider<_SearchQueryNotifier, String>(
  _SearchQueryNotifier.new,
);

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void set(String v) => state = v;
}

enum TransactionFilter { all, income, expense, transfer }

enum TimeFilter { allTime, lastMonth }

final transactionFilterProvider = NotifierProvider<_TransactionFilterNotifier, TransactionFilter>(
  _TransactionFilterNotifier.new,
);

class _TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.all;
  
  void set(TransactionFilter v) => state = v;
}

final timeFilterProvider = NotifierProvider<_TimeFilterNotifier, TimeFilter>(
  _TimeFilterNotifier.new,
);

class _TimeFilterNotifier extends Notifier<TimeFilter> {
  @override
  TimeFilter build() => TimeFilter.lastMonth;
  
  void set(TimeFilter v) => state = v;
}

final accountFilteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final activeAccount = ref.watch(activeAccountProvider);
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.value ?? [];

  if (activeAccount == null) {
    return txs;
  }

  return txs.where((t) => t.accountId == activeAccount.id).toList();
});

final globalTotalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? [];
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return txs.where((t) => t.category != 'Transfer').fold(0.0, (sum, t) {
    final converted = exchangeService.convert(
      t.amount,
      t.currencyCode,
      targetCurrency,
    );
    return t.type == TransactionType.income ? sum + converted : sum - converted;
  });
});

final totalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);

  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final globalCurrency = ref.watch(currencyProvider).code;

  String targetCurrency = globalCurrency;
  if (index > 0) {
    final accounts = accountsAsync.value ?? [];
    if (index <= accounts.length) {
      targetCurrency = accounts[index - 1].currency;
    }
  }

  final exchangeService = ref.watch(exchangeRateServiceProvider);

  return txs.where((t) => t.category != 'Transfer').fold(0.0, (sum, t) {
    final converted = exchangeService.convert(
      t.amount,
      t.currencyCode,
      targetCurrency,
    );
    return t.type == TransactionType.income ? sum + converted : sum - converted;
  });
});

final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final filtered = txs.where(
    (t) => t.type == TransactionType.income && t.category != 'Transfer',
  );

  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final globalCurrency = ref.watch(currencyProvider).code;

  String targetCurrency = globalCurrency;
  if (index > 0) {
    final accounts = accountsAsync.value ?? [];
    if (index <= accounts.length) {
      targetCurrency = accounts[index - 1].currency;
    }
  }

  final exchangeService = ref.watch(exchangeRateServiceProvider);

  return filtered.fold(0.0, (sum, t) {
    return sum +
        exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
  });
});

final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final filtered = txs.where(
    (t) => t.type == TransactionType.expense && t.category != 'Transfer',
  );

  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final globalCurrency = ref.watch(currencyProvider).code;

  String targetCurrency = globalCurrency;
  if (index > 0) {
    final accounts = accountsAsync.value ?? [];
    if (index <= accounts.length) {
      targetCurrency = accounts[index - 1].currency;
    }
  }

  final exchangeService = ref.watch(exchangeRateServiceProvider);

  return filtered.fold(0.0, (sum, t) {
    return sum +
        exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
  });
});

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final typeFilter = ref.watch(transactionFilterProvider);
  final timeFilter = ref.watch(timeFilterProvider);
  final activeAccount = ref.watch(activeAccountProvider);
  final transferPairs = ref.watch(transferPairsProvider);

  var filtered = txs;

  if (timeFilter == TimeFilter.lastMonth) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    filtered = filtered
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(end),
        )
        .toList();
  }

  if (typeFilter == TransactionFilter.income) {
    filtered = filtered.where((t) => t.type == TransactionType.income).toList();
  } else if (typeFilter == TransactionFilter.expense) {
    filtered = filtered
        .where((t) => t.type == TransactionType.expense)
        .toList();
  } else if (typeFilter == TransactionFilter.transfer) {
    filtered = filtered.where((t) => t.category == 'Transfer').toList();
  }

  if (query.isNotEmpty) {
    filtered = filtered.where((t) {
      final matchesCategory = t.category.toLowerCase().contains(query);
      final matchesNote = t.note?.toLowerCase().contains(query) ?? false;
      return matchesCategory || matchesNote;
    }).toList();
  }

  filtered.sort((a, b) => b.date.compareTo(a.date));

  if (activeAccount == null) {
    filtered = filtered.where((t) {
      if (t.category != 'Transfer') return true;
      if (t.type == TransactionType.income && transferPairs.containsKey(t.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  return filtered;
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(filteredTransactionsProvider).take(20).toList();
});

final accountsProvider = StreamProvider<List<Account>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAll();
});

final activeAccountIndexProvider = NotifierProvider<_ActiveAccountIndexNotifier, int>(
  _ActiveAccountIndexNotifier.new,
);

class _ActiveAccountIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void set(int v) => state = v;
}

final activeAccountProvider = Provider<Account?>((ref) {
  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);

  if (index == 0) return null;

  return accountsAsync.when(
    data: (accounts) {
      if (index > 0 && index <= accounts.length) {
        return accounts[index - 1];
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class CardColors {
  final Color primary;
  final Color secondary;
  final GradientType lightGradientType;
  final GradientType darkGradientType;

  const CardColors(
    this.primary,
    this.secondary,
    this.lightGradientType,
    this.darkGradientType,
  );

  GradientType gradientTypeForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? darkGradientType : lightGradientType;
}

final cardColorsProvider =
    NotifierProvider<CardColorsNotifier, CardColors>(
      CardColorsNotifier.new,
    );

final accountCardColorsProvider =
    NotifierProvider.family<AccountCardColorsNotifier, CardColors, int>(
      (accountId) => AccountCardColorsNotifier(accountId),
    );

class CardColorsNotifier extends Notifier<CardColors> {
  int _loadGeneration = 0;

  @override
  CardColors build() {
    ref.listen<ThemeMode>(themeProvider, (previous, next) {
      if (previous != null) {
        _onThemeChanged(previous, next);
      }
    });
    _load();
    return const CardColors(
      CardColorService.defaultPrimary,
      CardColorService.defaultSecondary,
      CardColorService.defaultGradientLight,
      CardColorService.defaultGradientDark,
    );
  }

  Future<void> _load() async {
    final currentGeneration = ++_loadGeneration;
    final (c1, c2, lightG, darkG) = await CardColorService.load();
    if (currentGeneration != _loadGeneration) return; 
    state = CardColors(c1, c2, lightG, darkG);
  }

  Future<void> save(
    Color primary,
    Color secondary,
    GradientType lightGradient,
    GradientType darkGradient,
  ) async {
    _loadGeneration++;
    state = CardColors(primary, secondary, lightGradient, darkGradient);
    await CardColorService.save(
      primary,
      secondary,
      lightGradient,
      darkGradient,
    );
  }

  Future<void> reset(bool isDark) async {
    final primary = isDark
        ? CardColorService.defaultPrimary
        : CardColorService.defaultPrimaryLight;
    final secondary = isDark
        ? CardColorService.defaultSecondary
        : CardColorService.defaultSecondaryLight;
    _loadGeneration++;
    state = CardColors(
      primary,
      secondary,
      CardColorService.defaultGradientLight,
      CardColorService.defaultGradientDark,
    );
    await CardColorService.save(
      primary,
      secondary,
      CardColorService.defaultGradientLight,
      CardColorService.defaultGradientDark,
    );
  }

  void _onThemeChanged(ThemeMode previous, ThemeMode next) {
    final previousBrightness = _resolve(previous);
    final nextBrightness = _resolve(next);

    if (previousBrightness == nextBrightness) return;

    final oldDefaults = _defaultsFor(previousBrightness);
    final newDefaults = _defaultsFor(nextBrightness);

    final isUsingOldDefaults =
        state.primary == oldDefaults.primary &&
        state.secondary == oldDefaults.secondary &&
        state.gradientTypeForBrightness(previousBrightness) ==
            oldDefaults.gradient;

    if (isUsingOldDefaults) {
      _loadGeneration++;
      state = CardColors(
        newDefaults.primary,
        newDefaults.secondary,
        state.lightGradientType,
        state.darkGradientType,
      );
    }
  }

  Brightness _resolve(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
    return mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  ({Color primary, Color secondary, GradientType gradient}) _defaultsFor(
    Brightness brightness,
  ) {
    return brightness == Brightness.dark
        ? (
            primary: CardColorService.defaultPrimary,
            secondary: CardColorService.defaultSecondary,
            gradient: CardColorService.defaultGradientDark,
          )
        : (
            primary: CardColorService.defaultPrimaryLight,
            secondary: CardColorService.defaultSecondaryLight,
            gradient: CardColorService.defaultGradientLight,
          );
  }
}

class AccountCardColorsNotifier extends Notifier<CardColors> {
  AccountCardColorsNotifier(this._accountId);

  final int _accountId;
  int _loadGeneration = 0;

  @override
  CardColors build() {
    ref.listen<ThemeMode>(themeProvider, (previous, next) {
      if (previous != null) {
        _onThemeChanged(previous, next);
      }
    });
    _load(_accountId);
    return const CardColors(
      CardColorService.defaultPrimary,
      CardColorService.defaultSecondary,
      CardColorService.defaultGradientLight,
      CardColorService.defaultGradientDark,
    );
  }

  Future<void> _load(int accountId) async {
    final currentGeneration = ++_loadGeneration;
    final (c1, c2, lightG, darkG) = await CardColorService.load(
      accountId: accountId,
    );
    if (currentGeneration != _loadGeneration) return;
    state = CardColors(c1, c2, lightG, darkG);
  }

  Future<void> save(
    Color primary,
    Color secondary,
    GradientType lightGradient,
    GradientType darkGradient,
  ) async {
    _loadGeneration++;
    state = CardColors(primary, secondary, lightGradient, darkGradient);
    await CardColorService.save(
      primary,
      secondary,
      lightGradient,
      darkGradient,
      accountId: _accountId,
    );
  }

  Future<void> reset(bool isDark) async {
    final primary = isDark
        ? CardColorService.defaultPrimary
        : CardColorService.defaultPrimaryLight;
    final secondary = isDark
        ? CardColorService.defaultSecondary
        : CardColorService.defaultSecondaryLight;
    _loadGeneration++;
    state = CardColors(
      primary,
      secondary,
      CardColorService.defaultGradientLight,
      CardColorService.defaultGradientDark,
    );
    await CardColorService.save(
      primary,
      secondary,
      CardColorService.defaultGradientLight,
      CardColorService.defaultGradientDark,
      accountId: _accountId,
    );
  }

  void _onThemeChanged(ThemeMode previous, ThemeMode next) {
    final previousBrightness = _resolve(previous);
    final nextBrightness = _resolve(next);

    if (previousBrightness == nextBrightness) return;

    final oldDefaults = _defaultsFor(previousBrightness);
    final newDefaults = _defaultsFor(nextBrightness);

    final isUsingOldDefaults =
        state.primary == oldDefaults.primary &&
        state.secondary == oldDefaults.secondary &&
        state.gradientTypeForBrightness(previousBrightness) ==
            oldDefaults.gradient;

    if (isUsingOldDefaults) {
      _loadGeneration++;
      state = CardColors(
        newDefaults.primary,
        newDefaults.secondary,
        state.lightGradientType,
        state.darkGradientType,
      );
    }
  }

  Brightness _resolve(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
    return mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  ({Color primary, Color secondary, GradientType gradient}) _defaultsFor(
    Brightness brightness,
  ) {
    return brightness == Brightness.dark
        ? (
            primary: CardColorService.defaultPrimary,
            secondary: CardColorService.defaultSecondary,
            gradient: CardColorService.defaultGradientDark,
          )
        : (
            primary: CardColorService.defaultPrimaryLight,
            secondary: CardColorService.defaultSecondaryLight,
            gradient: CardColorService.defaultGradientLight,
          );
  }
}
