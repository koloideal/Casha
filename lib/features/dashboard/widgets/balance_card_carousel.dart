import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/card_color_service.dart';
import '../../settings/provider.dart';
import '../provider.dart';
import 'balance_card.dart';

class BalanceCardCarousel extends ConsumerStatefulWidget {
  final double balance;
  final CurrencyInfo currencyInfo;
  final VoidCallback? onLongPress;
  final Color? previewPrimary;
  final Color? previewSecondary;
  final GradientType? previewGradientType;

  const BalanceCardCarousel({
    super.key,
    required this.balance,
    required this.currencyInfo,
    this.onLongPress,
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
    _pageController = PageController(viewportFraction: 1.0);
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
        // Debug logging
        debugPrint('BalanceCardCarousel: accounts.length = ${accounts.length}');
        if (accounts.isNotEmpty) {
          debugPrint('BalanceCardCarousel: first account = ${accounts[0].name}');
        }
        
        // Page 0: Total balance
        // Pages 1..N: Account cards
        // Page N+1: AddAccountCard (if < 5 accounts)
        final totalPages = 1 + accounts.length + (accounts.length < 5 ? 1 : 0);

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                clipBehavior: Clip.none,
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  ref.read(activeAccountIndexProvider.notifier).state = index;
                },
                itemBuilder: (context, index) {
                  Widget pageContent;
                  
                  if (index == 0) {
                    // Page 0: Total balance card
                    pageContent = BalanceCard(
                      balance: widget.balance,
                      currencyInfo: widget.currencyInfo,
                      onLongPress: widget.onLongPress,
                      previewPrimary: widget.previewPrimary,
                      previewSecondary: widget.previewSecondary,
                      previewGradientType: widget.previewGradientType,
                    );
                  } else if (index <= accounts.length) {
                    // Pages 1..N: Account cards
                    final account = accounts[index - 1];
                    debugPrint('BalanceCardCarousel: building account card at index $index for ${account.name}');
                    pageContent = _AccountBalanceCard(
                      account: account,
                      balance: widget.balance, // TODO: Calculate per-account balance
                      currencyInfo: widget.currencyInfo,
                    );
                  } else {
                    // Page N+1: AddAccountCard
                    pageContent = AddAccountCard(
                      onTap: () {},
                    );
                  }
                  
                  // Add horizontal padding to create gap between cards
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: pageContent,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _DotIndicators(
              count: totalPages,
              activeIndex: activeIndex,
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        debugPrint('BalanceCardCarousel error: $error');
        debugPrint('Stack: $stack');
        // Show total balance card on error
        return Column(
          children: [
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: BalanceCard(
                  balance: widget.balance,
                  currencyInfo: widget.currencyInfo,
                  onLongPress: widget.onLongPress,
                  previewPrimary: widget.previewPrimary,
                  previewSecondary: widget.previewSecondary,
                  previewGradientType: widget.previewGradientType,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DotIndicators(
              count: 1,
              activeIndex: 0,
            ),
          ],
        );
      },
    );
  }
}

class _AccountBalanceCard extends ConsumerWidget {
  final dynamic account;
  final double balance;
  final CurrencyInfo currencyInfo;

  const _AccountBalanceCard({
    required this.account,
    required this.balance,
    required this.currencyInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BalanceCard(
          balance: balance,
          currencyInfo: currencyInfo,
          onLongPress: null, // No long press for account cards
          previewPrimary: null,
          previewSecondary: null,
          previewGradientType: null,
        ),
        Positioned(
          top: 16,
          left: 24,
          child: Text(
            account.name,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Add account',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
        final segment = metric.extractPath(
          distance,
          distance + dashWidth,
        );
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

  const _DotIndicators({
    required this.count,
    required this.activeIndex,
  });

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
