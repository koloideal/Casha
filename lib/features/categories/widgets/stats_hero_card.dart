import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/services/card_color_service.dart';
import '../../../shared/providers/amount_format_provider.dart';
import '../../../shared/utils/card_gradient.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/byn_sign.dart';
import '../../dashboard/provider.dart';
import '../../settings/provider.dart';
import '../provider.dart';

class StatsHeroCard extends ConsumerWidget {
  final double amount;
  final String label;
  final Color accentColor;
  final String scopeLabel;

  const StatsHeroCard({
    super.key,
    required this.amount,
    required this.label,
    required this.accentColor,
    required this.scopeLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    final currencyInfo = ref.watch(statsCurrencyProvider);
    final brightness = Theme.of(context).brightness;
    final activeAccount = ref.watch(activeAccountProvider);
    final globalColors = ref.watch(cardColorsProvider);

    final CardColors colors;
    if (activeAccount != null) {
      colors = ref.watch(accountCardColorsProvider(activeAccount.id));
    } else {
      colors = globalColors;
    }

    final primary = Color.lerp(colors.primary, accentColor, 0.35)!;
    final secondary = Color.lerp(colors.secondary, accentColor, 0.2)!;
    final gradientType = colors.gradientTypeForBrightness(brightness);
    final onCard = primary.computeLuminance() > 0.35
        ? Colors.black
        : Colors.white;

    return Container(
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: buildCardGradient(primary, secondary, gradientType),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: onCard.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                scopeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onCard.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: onCard.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: currencyInfo.code == 'BYN'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BynSign(fontSize: 28, color: onCard),
                            const SizedBox(width: 2),
                            Text(
                              formatAmount('', amount, fmt),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: onCard,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        )
                      : Text(
                          formatAmount(currencyInfo.symbol, amount, fmt),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: onCard,
                          ),
                          maxLines: 1,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
