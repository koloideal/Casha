import 'package:flutter/material.dart';

String colorToHex(Color color) {
  final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return hex.substring(2);
}
