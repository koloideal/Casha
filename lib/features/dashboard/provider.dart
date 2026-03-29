import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/card_color_service.dart';
import '../../core/utils/result.dart';
import '../../data/database/app_database.dart' as db;
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository.dart';
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
  return AccountRepository(db);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>((
      ref,
    ) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionsNotifier(repository);
    });

class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAll();

    state = result.isSuccess
        ? AsyncValue.data(result.dataOrNull!)
        : AsyncValue.error(result.errorOrNull!, StackTrace.current);
  }

  Future<Result<void>> add(Transaction transaction) async {
    final result = await _repository.add(transaction);

    if (result.isSuccess) {
      await _load();
    }

    return result;
  }

  Future<Result<void>> update(Transaction transaction) async {
    final result = await _repository.update(transaction);

    if (result.isSuccess) {
      await _load();
    }

    return result;
  }

  Future<Result<void>> delete(String id) async {
    final result = await _repository.delete(id);

    if (result.isSuccess) {
      await _load();
    }

    return result;
  }

  Future<void> restore(Transaction transaction) async {
    await _repository.add(transaction);
    await _load();
  }

  Future<void> clearAll() async {
    await _repository.deleteAll();
    state = const AsyncValue.data([]);
  }

  Future<void> refresh() async {
    await _load();
  }
}

final transferPairsProvider = Provider<Map<String, Transaction>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
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

final searchQueryProvider = StateProvider<String>((ref) => '');

enum TransactionFilter { all, income, expense, transfer }

enum TimeFilter { allTime, lastMonth }

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter.all,
);

final timeFilterProvider = StateProvider<TimeFilter>(
  (ref) => TimeFilter.lastMonth,
);

final accountFilteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.valueOrNull ?? [];
  final activeAccount = ref.watch(activeAccountProvider);

  if (activeAccount == null) {
    return txs;
  }

  return txs.where((t) => t.accountId == activeAccount.id).toList();
});

final globalTotalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
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
    final accounts = accountsAsync.valueOrNull ?? [];
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
    final accounts = accountsAsync.valueOrNull ?? [];
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
    final accounts = accountsAsync.valueOrNull ?? [];
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

final currentMonthExpenseProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final filtered = txs.where(
    (t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month,
  );

  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final globalCurrency = ref.watch(currencyProvider).code;

  String targetCurrency = globalCurrency;
  if (index > 0) {
    final accounts = accountsAsync.valueOrNull ?? [];
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

final accountsProvider = StreamProvider<List<Account>>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  while (true) {
    yield await repository.getAll();
    await Future.delayed(const Duration(milliseconds: 100));
  }
});

final activeAccountIndexProvider = StateProvider<int>((ref) => 0);

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
    StateNotifierProvider<CardColorsNotifier, CardColors>((ref) {
      final notifier = CardColorsNotifier();
      notifier.setupThemeListener(ref);
      return notifier;
    });

final accountCardColorsProvider =
    StateNotifierProvider.family<CardColorsNotifier, CardColors, int>((
      ref,
      accountId,
    ) {
      final notifier = CardColorsNotifier(accountId: accountId);
      notifier.setupThemeListener(ref);
      return notifier;
    });

class CardColorsNotifier extends StateNotifier<CardColors> {
  final int? accountId;

  CardColorsNotifier({this.accountId})
    : super(
        const CardColors(
          CardColorService.defaultPrimary,
          CardColorService.defaultSecondary,
          CardColorService.defaultGradientLight,
          CardColorService.defaultGradientDark,
        ),
      ) {
    _load();
  }

  int _loadGeneration = 0;

  void setupThemeListener(Ref ref) {
    ref.listen<ThemeMode>(themeProvider, (previous, next) {
      if (previous != null) {
        _onThemeChanged(previous, next);
      }
    });
  }

  Future<void> _load() async {
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
      accountId: accountId,
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
      accountId: accountId,
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
