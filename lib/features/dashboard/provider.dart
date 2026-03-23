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

final searchQueryProvider = StateProvider<String>((ref) => '');

enum TransactionFilter { all, income, expense }

enum TimeFilter { allTime, lastMonth }

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter.all,
);

final timeFilterProvider = StateProvider<TimeFilter>(
  (ref) => TimeFilter.lastMonth,
);

// Base filtered transactions by active account
final accountFilteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final txs = txsAsync.valueOrNull ?? [];
  final activeAccount = ref.watch(activeAccountProvider);
  
  // If activeAccount is null (Total Balance page), return all transactions
  if (activeAccount == null) {
    return txs;
  }
  
  // Filter by account ID
  return txs.where((t) => t.accountId == activeAccount.id).toList();
});

final totalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return txs.fold(0.0, (sum, t) {
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
  final filtered = txs.where((t) => t.type == TransactionType.income);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

  return filtered.fold(0.0, (sum, t) {
    return sum +
        exchangeService.convert(t.amount, t.currencyCode, targetCurrency);
  });
});

final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(accountFilteredTransactionsProvider);
  final filtered = txs.where((t) => t.type == TransactionType.expense);
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

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
  final exchangeService = ref.watch(exchangeRateServiceProvider);
  final targetCurrency = ref.watch(currencyProvider).code;

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
  }

  if (query.isNotEmpty) {
    filtered = filtered.where((t) {
      final matchesCategory = t.category.toLowerCase().contains(query);
      final matchesNote = t.note?.toLowerCase().contains(query) ?? false;
      return matchesCategory || matchesNote;
    }).toList();
  }

  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(filteredTransactionsProvider).take(20).toList();
});

// Watches the list of all accounts
final accountsProvider = StreamProvider<List<Account>>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  while (true) {
    yield await repository.getAll();
    await Future.delayed(const Duration(milliseconds: 100));
  }
});

// Ephemeral UI state — active carousel index, starts at 0, not persisted
final activeAccountIndexProvider = StateProvider<int>((ref) => 0);

// Returns the currently active Account based on carousel index
final activeAccountProvider = Provider<Account?>((ref) {
  final index = ref.watch(activeAccountIndexProvider);
  final accountsAsync = ref.watch(accountsProvider);
  
  if (index == 0) return null; // 0 means "Total Balance"
  
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
  final GradientType gradientType;

  const CardColors(this.primary, this.secondary, this.gradientType);
}

final cardColorsProvider =
    StateNotifierProvider<CardColorsNotifier, CardColors>((ref) {
      final notifier = CardColorsNotifier();
      notifier.setupThemeListener(ref);
      return notifier;
    });

// Account-specific color provider
final accountCardColorsProvider =
    StateNotifierProvider.family<CardColorsNotifier, CardColors, int>((ref, accountId) {
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
          CardColorService.defaultGradient,
        ),
      ) {
    _load();
  }

  void setupThemeListener(Ref ref) {
    ref.listen<ThemeMode>(themeProvider, (previous, next) {
      if (previous != null) {
        _onThemeChanged(previous, next);
      }
    });
  }

  Future<void> _load() async {
    final (c1, c2, g) = await CardColorService.load(accountId: accountId);
    state = CardColors(c1, c2, g);
  }

  Future<void> save(
    Color primary,
    Color secondary,
    GradientType gradient,
  ) async {
    state = CardColors(primary, secondary, gradient);
    await CardColorService.save(primary, secondary, gradient, accountId: accountId);
  }

  Future<void> reset(bool isDark) async {
    final primary = isDark
        ? CardColorService.defaultPrimary
        : CardColorService.defaultPrimaryLight;
    final secondary = isDark
        ? CardColorService.defaultSecondary
        : CardColorService.defaultSecondaryLight;
    state = CardColors(primary, secondary, CardColorService.defaultGradient);
    await CardColorService.save(
      primary,
      secondary,
      CardColorService.defaultGradient,
      accountId: accountId,
    );
  }

  void _onThemeChanged(ThemeMode previous, ThemeMode next) {
    final previousBrightness = _resolve(previous);
    final nextBrightness = _resolve(next);

    // No change in actual brightness
    if (previousBrightness == nextBrightness) return;

    final oldDefaults = _defaultsFor(previousBrightness);
    final newDefaults = _defaultsFor(nextBrightness);

    // Check if current colors match old theme defaults
    final isUsingOldDefaults =
        state.primary == oldDefaults.primary &&
        state.secondary == oldDefaults.secondary &&
        state.gradientType == oldDefaults.gradient;

    // Only auto-switch if using default colors
    if (isUsingOldDefaults) {
      state = CardColors(
        newDefaults.primary,
        newDefaults.secondary,
        newDefaults.gradient,
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
            gradient: CardColorService.defaultGradient,
          )
        : (
            primary: CardColorService.defaultPrimaryLight,
            secondary: CardColorService.defaultSecondaryLight,
            gradient: CardColorService.defaultGradient,
          );
  }
}
