import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/haptic_service.dart';
import 'data/database/app_database.dart';
import 'features/dashboard/provider.dart';
import 'shared/services/onboarding_service.dart';

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
