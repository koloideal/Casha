import 'package:flutter/material.dart';
import 'transaction.dart';

class AppCategory {
  final String key;
  final TransactionType type;
  final String labelEn;
  final String labelRu;
  final IconData icon;
  final Color color;
  final String iconName;
  final bool isCustom;
  final int? id;

  const AppCategory({
    required this.key,
    required this.type,
    required this.labelEn,
    required this.labelRu,
    required this.icon,
    required this.color,
    required this.iconName,
    this.isCustom = false,
    this.id,
  });

  String label(bool isRu) {
    final value = isRu ? labelRu : labelEn;
    return value.isEmpty ? key : value;
  }
}
