import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/haptic_service.dart';
import 'data/database/app_database.dart';
import 'features/dashboard/provider.dart';
import 'shared/services/onboarding_service.dart';
import 'shared/services/billing_service.dart';
import 'shared/services/premium_manager.dart';
import 'shared/providers/billing_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ru', null);

  final prefs = await SharedPreferences.getInstance();
  await HapticService.init();
  OnboardingService(prefs);

  final database = AppDatabase();

  final billing = kDebugMode
      ? DebugBillingService(prefs)
      : PlayBillingService();
  final premiumManager = PremiumManager(prefs, billing);
  await premiumManager.autoRestore();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(database),
        billingServiceProvider.overrideWithValue(billing),
      ],
      child: const App(),
    ),
  );
}
