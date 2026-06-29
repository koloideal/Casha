import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CashaShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const CashaShimmerText({
    required this.text,
    this.style,
    super.key,
  });

  @override
  State<CashaShimmerText> createState() => _CashaShimmerTextState();
}

class _CashaShimmerTextState extends State<CashaShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _tilt = 0.0;
  double _targetTilt = 0.0;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      _targetTilt = (e.x / 9.8).clamp(-1.0, 1.0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _tilt += (_targetTilt - _tilt) * 0.12;

        final sweep = (_controller.value * 2.0 - 1.0) + _tilt * 0.6;

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(sweep - 0.8, -0.3),
              end: Alignment(sweep + 0.8, 0.3),
              colors: [
                primary.withValues(alpha: 0.7),
                primary,
                Colors.white,
                primary.withValues(alpha: 0.9),
                Colors.white,
                primary,
                primary.withValues(alpha: 0.7),
              ],
              stops: [0.0, 0.2, 0.35, 0.45, 0.55, 0.8, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style?.copyWith(color: Colors.white),
      ),
    );
  }
}
