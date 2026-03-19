import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const accent = Color(0xFF7C6DED);
  static const income = Color(0xFF4CAF8C);
  static const expense = Color(0xFFE05C6B);
  static const textPrimary = Color(0xFFEEEEF5);
  static const textSecondary = Color(0xFF8888A0);
  static const divider = Color(0xFF2A2A38);
}

class AppCategories {
  static const all = ['Food', 'Transport', 'Shopping', 'Health', 'Other'];

  static const icons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Health': Icons.favorite_rounded,
    'Other': Icons.category_rounded,
  };

  static const colors = {
    'Food': Color(0xFFFF8C69),
    'Transport': Color(0xFF69B4FF),
    'Shopping': Color(0xFFFFD369),
    'Health': Color(0xFF69FFB4),
    'Other': Color(0xFFB469FF),
  };
}
