import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/card_color_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/widgets/byn_sign.dart';
import '../../settings/provider.dart';
import '../provider.dart';

String _smartBalance(double amount, AmountFormat fmt, String symbol) {
  final isWhole = amount == amount.floorToDouble();

  String formatted;
  if (isWhole) {
    formatted = fmt.format(amount);
    if (formatted.endsWith('.00')) {
      formatted = formatted.substring(0, formatted.length - 3);
    }
  } else {
    formatted = fmt.format(amount);
  }
  return symbol.isEmpty ? formatted : '$symbol$formatted';
}

class BalanceCard extends ConsumerStatefulWidget {
  final double balance;
  final CurrencyInfo currencyInfo;
  final VoidCallback? onLongPress;
  final Color? previewPrimary;
  final Color? previewSecondary;
  final GradientType? previewGradientType;
  final String? accountName;
  final CardColors? accountColors;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.currencyInfo,
    this.onLongPress,
    this.previewPrimary,
    this.previewSecondary,
    this.previewGradientType,
    this.accountName,
    this.accountColors,
  });

  @override
  ConsumerState<BalanceCard> createState() => BalanceCardState();
}

class BalanceCardState extends ConsumerState<BalanceCard>
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
      duration: const Duration(seconds: 1),
    )..repeat();

    _sub =
        accelerometerEventStream(
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

  Gradient _buildGradient(Color primary, Color secondary, GradientType type) {
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final rates = ref.read(exchangeRateServiceProvider);
    final fmt = ref.watch(amountFormatProvider);
    final showConversions = ref.watch(showCurrencyConversionsProvider);

    final globalColors = ref.watch(cardColorsProvider);
    final savedColors = widget.accountColors ?? globalColors;
    final primary = widget.previewPrimary ?? savedColors.primary;
    final secondary = widget.previewSecondary ?? savedColors.secondary;
    final gradientType = widget.previewGradientType ?? savedColors.gradientType;

    final others = kDisplayCurrencies
        .where((c) => c.$1 != widget.currencyInfo.code)
        .toList();

    final textColorMode = ref.watch(cardTextColorProvider);
    final Color onCard;
    switch (textColorMode) {
      case CardTextColorMode.white:
        onCard = Colors.white;
      case CardTextColorMode.black:
        onCard = Colors.black;
      case CardTextColorMode.adaptive:
        onCard = primary.computeLuminance() > 0.3 ? Colors.black : Colors.white;
    }

    return GestureDetector(
      onLongPress: () {
        HapticService.heavy();
        widget.onLongPress?.call();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          _tiltX += (_targetTiltX - _tiltX) * 0.15;
          _tiltY += (_targetTiltY - _tiltY) * 0.15;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_tiltX * 0.42)
              ..rotateY(_tiltY * 0.42),
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _buildGradient(primary, secondary, gradientType),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    if (widget.accountName != null)
                      Positioned(
                        top: 20,
                        left: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              widget.accountName!,
                              style: TextStyle(
                                color: onCard.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (widget.accountName == null)
                                  Text(
                                    s.totalBalance,
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                      color: onCard.withOpacity(0.6),
                                    ),
                                  ),
                                if (widget.accountName == null)
                                  const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: widget.currencyInfo.code == 'BYN'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            BynSign(
                                              fontSize: 48,
                                              color: onCard,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              _smartBalance(
                                                widget.balance,
                                                fmt,
                                                '',
                                              ),
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w700,
                                                color: onCard,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          _smartBalance(
                                            widget.balance,
                                            fmt,
                                            widget.currencyInfo.symbol,
                                          ),
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w700,
                                            color: onCard,
                                          ),
                                          maxLines: 1,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.balance != 0 && showConversions) ...[
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 70,
                              color: onCard.withOpacity(0.15),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 110,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: others.map((c) {
                                  final converted = rates.convert(
                                    widget.balance,
                                    widget.currencyInfo.code,
                                    c.$1,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: c.$1 == 'BYN'
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                BynSign(
                                                  fontSize: 14,
                                                  color: onCard.withOpacity(
                                                    0.65,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  _smartBalance(
                                                    converted,
                                                    fmt,
                                                    '',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: onCard.withOpacity(
                                                      0.65,
                                                    ),
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ],
                                            )
                                          : Text(
                                              _smartBalance(
                                                converted,
                                                fmt,
                                                c.$2,
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: onCard.withOpacity(0.65),
                                              ),
                                              maxLines: 1,
                                            ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Text(
                        s.tapAndHoldToEdit,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: onCard.withOpacity(0.18),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
