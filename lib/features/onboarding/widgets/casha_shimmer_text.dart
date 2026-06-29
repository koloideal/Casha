import 'dart:async';
import 'dart:math';
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
  double _tiltX = 0.0, _tiltY = 0.0;
  double _targetTiltX = 0.0, _targetTiltY = 0.0;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      _targetTiltY = (e.x / 9.8).clamp(-1.0, 1.0);
      _targetTiltX = ((e.y / 9.8) - 1.0).clamp(-1.0, 1.0);
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
    final secondary = Theme.of(context).colorScheme.secondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _tiltX += (_targetTiltX - _tiltX) * 0.15;
        _tiltY += (_targetTiltY - _tiltY) * 0.15;

        final t = _controller.value;
        final shimmer = sin(t * 2 * pi) * 0.08;

        final gx = (_tiltY + shimmer).clamp(-1.0, 1.0);
        final gy = (_tiltX + shimmer * 0.5).clamp(-1.0, 1.0);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltX * 0.85)
            ..rotateY(_tiltY * 0.85),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(gx - 0.8, gy - 0.4),
                end: Alignment(gx + 0.8, gy + 0.4),
                colors: [
                  primary.withOpacity(0.7),
                  primary,
                  secondary,
                  Colors.white,
                  secondary,
                  primary,
                  primary.withOpacity(0.7),
                ],
                stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        style: widget.style?.copyWith(color: Colors.white),
      ),
    );
  }
}
