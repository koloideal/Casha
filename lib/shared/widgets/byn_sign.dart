import 'package:flutter/material.dart';

class BynSign extends StatelessWidget {
  final double fontSize;
  final Color color;

  const BynSign({super.key, required this.fontSize, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, fontSize * -0.12),
      child: Text(
        '\uE901',
        style: TextStyle(
          fontFamily: 'BynSymbol',
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
