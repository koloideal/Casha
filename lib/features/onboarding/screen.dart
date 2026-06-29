import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/haptic_service.dart';
import 'provider.dart';
import 'widgets/fade_slide_in.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    ref.read(onboardingProvider.notifier).setPage(page);
    HapticService.light();
    if (page == 4) {
      HapticService.medium();
      ref.read(onboardingProvider.notifier).complete();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) context.go('/dashboard');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final currentPage = ref.watch(onboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: [
                  OnboardingPage.welcome(
                    welcomeText: s.onboardingWelcome,
                    isActive: currentPage == 0,
                  ),
                  OnboardingPage.content(
                    icon: Icons.currency_exchange_rounded,
                    headline: s.onboardingMultiCurrencyTitle,
                    description: s.onboardingMultiCurrencyBody,
                    isActive: currentPage == 1,
                  ),
                  OnboardingPage.content(
                    icon: Icons.credit_card_rounded,
                    headline: s.onboardingCardsTitle,
                    description: s.onboardingCardsBody,
                    isActive: currentPage == 2,
                  ),
                  _ReadyPage(isActive: currentPage == 3),
                  const SizedBox.shrink(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: OnboardingPageIndicator(
                current: currentPage,
                count: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyPage extends ConsumerWidget {
  final bool isActive;

  const _ReadyPage({required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeSlideIn(
              active: isActive,
              child: Icon(
                Icons.waving_hand_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              active: isActive,
              delay: const Duration(milliseconds: 150),
              child: Text(
                s.onboardingReadyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              active: isActive,
              delay: const Duration(milliseconds: 300),
              child: Text(
                s.onboardingReadyBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              active: isActive,
              delay: const Duration(milliseconds: 450),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.onboardingSwipeRight,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
