import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GradientType { linear, radial, sweep, linearReverse }

class CardColorService {
  static const _key1 = 'card_color_primary';
  static const _key2 = 'card_color_secondary';
  static const _keyGradient = 'card_gradient_type';

  // DARK theme defaults — lighter, more vibrant purples
  static const defaultPrimary = Color(0xFF9B8FFF);        // light violet
  static const defaultSecondary = Color(0xFF6B5DD3);      // medium purple

  // LIGHT theme defaults — deep, saturated darks
  static const defaultPrimaryLight = Color(0xFF2D1B8E);   // deep indigo
  static const defaultSecondaryLight = Color(0xFF1A0F5C); // very dark navy

  static const defaultGradient = GradientType.linear;

  static Future<(Color, Color, GradientType)> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = prefs.getInt(_key1);
    final c2 = prefs.getInt(_key2);
    final g = prefs.getInt(_keyGradient);
    return (
      c1 != null ? Color(c1) : defaultPrimary,
      c2 != null ? Color(c2) : defaultSecondary,
      g != null ? GradientType.values[g] : defaultGradient,
    );
  }

  static Future<void> save(Color primary, Color secondary, GradientType gradient) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key1, primary.value);
    await prefs.setInt(_key2, secondary.value);
    await prefs.setInt(_keyGradient, gradient.index);
  }

  static Future<void> reset(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key1);
    await prefs.remove(_key2);
    await prefs.remove(_keyGradient);
  }
}
