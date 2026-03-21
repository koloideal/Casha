import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/provider.dart';
import 'app_strings.dart';

class LocaleNotifier extends Notifier<AppLocale> {
  static const _key = 'app_locale';

  @override
  AppLocale build() {
    // Load persisted locale synchronously via ref
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    return saved == 'ru' ? AppLocale.ru : AppLocale.en;
  }

  void setLocale(AppLocale locale) {
    state = locale;
    ref.read(sharedPreferencesProvider).setString(_key, locale.name);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(
  LocaleNotifier.new,
);

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});
