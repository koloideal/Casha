import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _key = 'onboarding_completed';
  static bool _shownInSession = false;

  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  bool get shouldShowOnboarding {
    if (kDebugMode) {
      return !_shownInSession;
    }
    return !(_prefs.getBool(_key) ?? false);
  }

  Future<void> completeOnboarding() async {
    _shownInSession = true;
    if (!kDebugMode) {
      await _prefs.setBool(_key, true);
    }
  }
}
