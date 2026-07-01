import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/provider.dart';
import '../models/user_model.dart';
import '../services/premium_manager.dart';
import 'billing_provider.dart';
import 'current_user_provider.dart';

final premiumManagerProvider = Provider<PremiumManager>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final billing = ref.watch(billingServiceProvider);
  return PremiumManager(prefs, billing);
});

final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.plan == UserPlan.vip;
});

final purchaseTokenProvider = Provider<String?>((ref) {
  final manager = ref.watch(premiumManagerProvider);
  return manager.purchaseToken;
});
