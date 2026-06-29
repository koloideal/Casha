import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/locale_provider.dart';
import 'provider.dart';
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

  void _finish() {
    ref.read(onboardingProvider.notifier).complete();
    context.go('/dashboard');
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
                onPageChanged: (page) =>
                    ref.read(onboardingProvider.notifier).setPage(page),
                children: [
                  OnboardingPage.welcome(welcomeText: s.onboardingWelcome),
                  OnboardingPage.content(
                    icon: Icons.currency_exchange_rounded,
                    headline: s.onboardingMultiCurrencyTitle,
                    description: s.onboardingMultiCurrencyBody,
                  ),
                  OnboardingPage.content(
                    icon: Icons.credit_card_rounded,
                    headline: s.onboardingCardsTitle,
                    description: s.onboardingCardsBody,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                children: [
                  OnboardingPageIndicator(
                    current: currentPage,
                    count: 3,
                  ),
                  const SizedBox(height: 32),
                  if (currentPage == 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finish,
                          child: Text(s.onboardingGetStarted),
                        ),
                      ),
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
