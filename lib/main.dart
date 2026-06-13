import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app/app.dart';
import 'core/services/haptic_service.dart';
import 'data/database/app_database.dart' hide Account, Transaction;
import 'data/repositories/account_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/dashboard/provider.dart';
import 'shared/models/account.dart';
import 'shared/models/transaction.dart';

Future<void> seedTestData(AppDatabase database) async {
  final accountRepo = AccountRepository(database);
  final transactionRepo = TransactionRepository(database);

  final existingAccounts = await accountRepo.getAll();
  if (existingAccounts.length > 1) {
    return;
  }

  final now = DateTime.now();
  final uuid = const Uuid();

  final cashId = await accountRepo.add(
    Account(
      id: 0,
      name: 'Cash',
      isMain: false,
      sortOrder: 1,
      currency: 'USD',
      createdAt: now,
    ),
  );

  final cardId = await accountRepo.add(
    Account(
      id: 0,
      name: 'Card',
      isMain: false,
      sortOrder: 2,
      currency: 'USD',
      createdAt: now,
    ),
  );

  final savingsId = await accountRepo.add(
    Account(
      id: 0,
      name: 'Savings',
      isMain: false,
      sortOrder: 3,
      currency: 'USD',
      createdAt: now,
    ),
  );

  final transactions = [
    Transaction(
      id: uuid.v4(),
      amount: 3500.0,
      category: 'Salary',
      type: TransactionType.income,
      date: now.subtract(const Duration(days: 28)),
      note: 'Monthly salary',
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 85.50,
      category: 'Groceries',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 27)),
      note: 'Weekly shopping',
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 45.00,
      category: 'Transportation',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 25)),
      accountId: cashId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 120.00,
      category: 'Utilities',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 22)),
      note: 'Electricity bill',
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 200.0,
      category: 'Freelance',
      type: TransactionType.income,
      date: now.subtract(const Duration(days: 20)),
      note: 'Side project',
      accountId: cashId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 500.0,
      category: 'Savings',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 18)),
      note: 'Monthly savings',
      accountId: savingsId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 65.25,
      category: 'Dining',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 15)),
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 30.00,
      category: 'Entertainment',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 12)),
      note: 'Movie tickets',
      accountId: cashId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 95.00,
      category: 'Groceries',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 10)),
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 150.0,
      category: 'Bonus',
      type: TransactionType.income,
      date: now.subtract(const Duration(days: 8)),
      note: 'Performance bonus',
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 75.00,
      category: 'Shopping',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 6)),
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 40.00,
      category: 'Transportation',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 4)),
      accountId: cashId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 55.80,
      category: 'Dining',
      type: TransactionType.expense,
      date: now.subtract(const Duration(days: 2)),
      note: 'Dinner with friends',
      accountId: cardId,
    ),
    Transaction(
      id: uuid.v4(),
      amount: 100.0,
      category: 'Gift',
      type: TransactionType.income,
      date: now.subtract(const Duration(days: 1)),
      accountId: cashId,
    ),
  ];

  for (final transaction in transactions) {
    await transactionRepo.add(transaction);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ru', null);

  final prefs = await SharedPreferences.getInstance();
  await HapticService.init();

  final database = AppDatabase();
  
  await seedTestData(database);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const App(),
    ),
  );
}
