import 'package:flutter/material.dart';
import '../../core/services/card_color_service.dart';

Gradient buildCardGradient(Color primary, Color secondary, GradientType type) {
  final colorDark = Color.lerp(secondary, Colors.black, 0.3)!;

  switch (type) {
    case GradientType.linear:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary, colorDark],
        stops: const [0.0, 0.6, 1.0],
      );
    case GradientType.linearReverse:
      return LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [primary, secondary, colorDark],
        stops: const [0.0, 0.6, 1.0],
      );
    case GradientType.radial:
      return RadialGradient(
        center: Alignment.center,
        radius: 1.4,
        colors: [primary, secondary, colorDark],
        stops: const [0.0, 0.6, 1.0],
      );
    case GradientType.sweep:
      return SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: 3.14159 * 2,
        colors: [primary, secondary, colorDark, secondary, primary],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    case GradientType.solid:
      return LinearGradient(
        colors: [primary, primary, primary],
        stops: const [0.0, 0.5, 1.0],
      );
  }
}
