import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/haptic_service.dart';
import 'features/dashboard/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for both locales
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ru', null);
  
  final prefs = await SharedPreferences.getInstance();
  await HapticService.init();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
