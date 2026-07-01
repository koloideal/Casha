import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GradientType { linear, linearReverse, radial, sweep, solid }

class CardColorService {
  static const _key1 = 'card_color_primary';
  static const _key2 = 'card_color_secondary';
  static const _keyGradientLegacy = 'card_gradient_type';
  static const _keyGradientLight = 'gradient_type_light';
  static const _keyGradientDark = 'gradient_type_dark';

  static const defaultPrimary = Color(0xFF4CAF8C);
  static const defaultSecondary = Color(0xFF4CAF8C);

  static const defaultPrimaryLight = Color(0xFF4CAF8C);
  static const defaultSecondaryLight = Color(0xFF4CAF8C);

  static const defaultGradientLight = GradientType.solid;
  static const defaultGradientDark = GradientType.solid;

  static Future<(Color, Color, GradientType, GradientType)> load({
    int? accountId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = accountId != null ? '${_key1}_$accountId' : _key1;
    final key2 = accountId != null ? '${_key2}_$accountId' : _key2;
    final keyGLight = accountId != null
        ? '${_keyGradientLight}_$accountId'
        : _keyGradientLight;
    final keyGDark = accountId != null
        ? '${_keyGradientDark}_$accountId'
        : _keyGradientDark;
    final keyGLegacy = accountId != null
        ? '${_keyGradientLegacy}_$accountId'
        : _keyGradientLegacy;
    
    final c1 = prefs.getInt(key1);
    final c2 = prefs.getInt(key2);

    final legacyIndex = prefs.getInt(keyGLegacy);
    GradientType parseWithDefault(int? index, GradientType fallback) {
      if (index == null) return fallback;
      final parsed = GradientType.values.elementAtOrNull(index);
      return parsed ?? fallback;
    }

    final lightIndex = prefs.getInt(keyGLight);
    final darkIndex = prefs.getInt(keyGDark);
    return (
      c1 != null ? Color(c1) : defaultPrimary,
      c2 != null ? Color(c2) : defaultSecondary,
      parseWithDefault(lightIndex ?? legacyIndex, defaultGradientLight),
      parseWithDefault(darkIndex ?? legacyIndex, defaultGradientDark),
    );
  }

  static Future<void> save(
    Color primary,
    Color secondary,
    GradientType lightGradient,
    GradientType darkGradient, {
    int? accountId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = accountId != null ? '${_key1}_$accountId' : _key1;
    final key2 = accountId != null ? '${_key2}_$accountId' : _key2;
    final keyGLight = accountId != null
        ? '${_keyGradientLight}_$accountId'
        : _keyGradientLight;
    final keyGDark = accountId != null
        ? '${_keyGradientDark}_$accountId'
        : _keyGradientDark;
    
    await prefs.setInt(key1, primary.value);
    await prefs.setInt(key2, secondary.value);
    await prefs.setInt(keyGLight, lightGradient.index);
    await prefs.setInt(keyGDark, darkGradient.index);
  }

  static Future<void> reset(bool isDark, {int? accountId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = accountId != null ? '${_key1}_$accountId' : _key1;
    final key2 = accountId != null ? '${_key2}_$accountId' : _key2;
    final keyGLight = accountId != null
        ? '${_keyGradientLight}_$accountId'
        : _keyGradientLight;
    final keyGDark = accountId != null
        ? '${_keyGradientDark}_$accountId'
        : _keyGradientDark;
    final keyGLegacy = accountId != null
        ? '${_keyGradientLegacy}_$accountId'
        : _keyGradientLegacy;
    
    await prefs.remove(key1);
    await prefs.remove(key2);
    await prefs.remove(keyGLight);
    await prefs.remove(keyGDark);
    await prefs.remove(keyGLegacy);
  }
}
