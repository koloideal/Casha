import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/onboarding_provider.dart';

class OnboardingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page) => state = page;

  Future<void> complete() async {
    final service = ref.read(onboardingServiceProvider);
    await service.completeOnboarding();
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, int>(
  OnboardingNotifier.new,
);
