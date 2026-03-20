import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardColorService {
  static const _key1 = 'card_color_primary';
  static const _key2 = 'card_color_secondary';

  // defaults match existing gradient: Color(0xFF6B5DD3) and Color(0xFF2A2040)
  static const defaultPrimary = Color(0xFF6B5DD3);
  static const defaultSecondary = Color(0xFF2A2040);

  static Future<(Color, Color)> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = prefs.getInt(_key1);
    final c2 = prefs.getInt(_key2);
    return (
      c1 != null ? Color(c1) : defaultPrimary,
      c2 != null ? Color(c2) : defaultSecondary,
    );
  }

  static Future<void> save(Color primary, Color secondary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key1, primary.value);
    await prefs.setInt(_key2, secondary.value);
  }
}
