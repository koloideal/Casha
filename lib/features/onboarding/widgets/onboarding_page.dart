import 'package:flutter/material.dart';
import 'casha_shimmer_text.dart';

class OnboardingPage extends StatelessWidget {
  final IconData? icon;
  final String? headline;
  final String? description;
  final String? welcomeText;
  final bool isWelcomePage;

  const OnboardingPage.welcome({required this.welcomeText, super.key})
      : icon = null,
        headline = null,
        description = null,
        isWelcomePage = true;

  const OnboardingPage.content({
    required this.icon,
    required this.headline,
    required this.description,
    super.key,
  })  : welcomeText = null,
        isWelcomePage = false;

  @override
  Widget build(BuildContext context) {
    if (isWelcomePage) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              welcomeText!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 12),
            CashaShimmerText(
              text: 'Casha',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
            ),
          ],
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              headline!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
