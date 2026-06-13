import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/card_color_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/transaction.dart';
import '../../settings/provider.dart';
import '../provider.dart';
import 'balance_card.dart';

class BalanceCardCarousel extends ConsumerStatefulWidget {
  final double balance;
  final CurrencyInfo currencyInfo;
  final VoidCallback? onLongPress;
  final void Function(Account)? onAccountLongPress;
  final VoidCallback? onAddAccountTap;
  final Color? previewPrimary;
  final Color? previewSecondary;
  final GradientType? previewGradientType;

  const BalanceCardCarousel({
    super.key,
    required this.balance,
    required this.currencyInfo,
    this.onLongPress,
    this.onAccountLongPress,
    this.onAddAccountTap,
    this.previewPrimary,
    this.previewSecondary,
    this.previewGradientType,
  });

  @override
  ConsumerState<BalanceCardCarousel> createState() =>
      _BalanceCardCarouselState();
}

class _BalanceCardCarouselState extends ConsumerState<BalanceCardCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final savedIndex = ref.read(activeAccountIndexProvider);
    _pageController = PageController(
      viewportFraction: 0.92,
      initialPage: savedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final activeIndex = ref.watch(activeAccountIndexProvider);

    return accountsAsync.when(
      data: (accounts) {
        final totalPages = 1 + accounts.length + (accounts.length < 5 ? 1 : 0);

        return Column(
          children: [
            SizedBox(
              height: 230,
              child: OverflowBox(
                maxWidth: MediaQuery.of(context).size.width,
                child: PageView.builder(
                  controller: _pageController,
                  clipBehavior:
                      Clip.none, 
                  itemCount: totalPages,
                  onPageChanged: (index) {
                    ref.read(activeAccountIndexProvider.notifier).set(index);
                    if (ref.read(hapticEnabledProvider)) {
                      HapticService.light();
                    }
                  },
                  itemBuilder: (context, index) {
                    Widget cardWidget;

                    if (index == 0) {
                      final totalBalance = ref.watch(
                        globalTotalBalanceProvider,
                      );
                      final globalCurrency = ref.watch(currencyProvider);
                      cardWidget = BalanceCard(
                        balance: totalBalance,
                        currencyInfo: globalCurrency,
                        onLongPress: widget.onLongPress,
                        previewPrimary: widget.previewPrimary,
                        previewSecondary: widget.previewSecondary,
                        previewGradientType: widget.previewGradientType,
                      );
                    } else if (index <= accounts.length) {
                      final account = accounts[index - 1];
                      final accountColors = ref.watch(
                        accountCardColorsProvider(account.id),
                      );

                      final txs =
                          ref.watch(transactionsProvider).value ?? [];
                      final accountTxs = txs
                          .where((t) => t.accountId == account.id)
                          .toList();
                      final exchangeService = ref.watch(
                        exchangeRateServiceProvider,
                      );
                      final accountBalance = accountTxs.fold(0.0, (sum, t) {
                        final converted = exchangeService.convert(
                          t.amount,
                          t.currencyCode,
                          account
                              .currency, 
                        );
                        return t.type == TransactionType.income
                            ? sum + converted
                            : sum - converted;
                      });

                      cardWidget = BalanceCard(
                        balance:
                            accountBalance, 
                        currencyInfo: CurrencyInfo(
                          currencyMap[account.currency]?.symbol ?? '\$',
                          account.currency,
                        ),
                        onLongPress: () =>
                            widget.onAccountLongPress?.call(account),
                        accountName: account.name,
                        accountColors: accountColors,
                      );
                    } else {
                      cardWidget = AddAccountCard(
                        onTap: widget.onAddAccountTap,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: cardWidget,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DotIndicators(count: totalPages, activeIndex: activeIndex),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        return Column(
          children: [
            SizedBox(
              height: 220,
              child: BalanceCard(
                balance: widget.balance,
                currencyInfo: widget.currencyInfo,
                onLongPress: widget.onLongPress,
                previewPrimary: widget.previewPrimary,
                previewSecondary: widget.previewSecondary,
                previewGradientType: widget.previewGradientType,
              ),
            ),
            const SizedBox(height: 12),
            const _DotIndicators(count: 1, activeIndex: 0),
          ],
        );
      },
    );
  }
}

class AddAccountCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddAccountCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),  
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Container(
            width: double.infinity,
            height: 205, 
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 36,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add account',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    const radius = 20.0;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotIndicators extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotIndicators({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF7C6DED)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}
