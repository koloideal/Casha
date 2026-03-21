import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static const _key = 'haptic_enabled';
  static bool _enabled = true; // runtime cache

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? true;
  }

  static bool get isEnabled => _enabled;

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }
}
