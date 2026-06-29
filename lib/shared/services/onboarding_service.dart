import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _key = 'onboarding_completed';
  static bool _shownInSession = false;
  static SharedPreferences? _staticPrefs;

  final SharedPreferences _prefs;

  OnboardingService(this._prefs) {
    _staticPrefs = _prefs;
  }

  static bool get shouldShowOnboarding {
    if (kDebugMode) {
      return !_shownInSession;
    }
    return !(_staticPrefs?.getBool(_key) ?? false);
  }

  static void markCompleted() {
    _shownInSession = true;
  }

  bool get shouldShowOnboardingInstance => shouldShowOnboarding;

  Future<void> completeOnboarding() async {
    _shownInSession = true;
    if (!kDebugMode) {
      await _prefs.setBool(_key, true);
    }
  }
}
