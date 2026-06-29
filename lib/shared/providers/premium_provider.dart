import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/provider.dart';
import '../services/premium_manager.dart';
import 'billing_provider.dart';

final premiumManagerProvider = Provider<PremiumManager>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final billing = ref.watch(billingServiceProvider);
  return PremiumManager(prefs, billing);
});

final isPremiumProvider = Provider<bool>((ref) {
  final manager = ref.watch(premiumManagerProvider);
  return manager.isPremium;
});

final purchaseTokenProvider = Provider<String?>((ref) {
  final manager = ref.watch(premiumManagerProvider);
  return manager.purchaseToken;
});
