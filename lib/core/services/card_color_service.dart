import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GradientType { linear, linearReverse, radial, sweep, solid }

class CardColorService {
  static const _key1 = 'card_color_primary';
  static const _key2 = 'card_color_secondary';
  static const _keyGradient = 'card_gradient_type';

  static const defaultPrimary = Color(0xFF5E5D5D);
  static const defaultSecondary = Color(0xFF9E9E9E);

  static const defaultPrimaryLight = Color(0xFF6A6482);
  static const defaultSecondaryLight = Color(0xFF000000);

  static const defaultGradient = GradientType.sweep;

  static Future<(Color, Color, GradientType)> load({int? accountId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = accountId != null ? '${_key1}_$accountId' : _key1;
    final key2 = accountId != null ? '${_key2}_$accountId' : _key2;
    final keyG = accountId != null ? '${_keyGradient}_$accountId' : _keyGradient;
    
    final c1 = prefs.getInt(key1);
    final c2 = prefs.getInt(key2);
    final g = prefs.getInt(keyG);
    return (
      c1 != null ? Color(c1) : defaultPrimary,
      c2 != null ? Color(c2) : defaultSecondary,
      g != null ? GradientType.values[g] : defaultGradient,
    );
  }

  static Future<void> save(
    Color primary,
    Color secondary,
    GradientType gradient, {
    int? accountId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = accountId != null ? '${_key1}_$accountId' : _key1;
    final key2 = accountId != null ? '${_key2}_$accountId' : _key2;
    final keyG = accountId != null ? '${_keyGradient}_$accountId' : _keyGradient;
    
    await prefs.setInt(key1, primary.value);
    await prefs.setInt(key2, secondary.value);
    await prefs.setInt(keyG, gradient.index);
  }

  static Future<void> reset(bool isDark, {int? accountId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = accountId != null ? '${_key1}_$accountId' : _key1;
    final key2 = accountId != null ? '${_key2}_$accountId' : _key2;
    final keyG = accountId != null ? '${_keyGradient}_$accountId' : _keyGradient;
    
    await prefs.remove(key1);
    await prefs.remove(key2);
    await prefs.remove(keyG);
  }
}
