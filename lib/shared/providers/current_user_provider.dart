import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/provider.dart';
import '../models/user_model.dart';
import '../services/premium_manager.dart';
import 'billing_provider.dart';

class CurrentUserNotifier extends Notifier<UserModel> {
  @override
  UserModel build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final billing = ref.watch(billingServiceProvider);
    final manager = PremiumManager(prefs, billing);
    return UserModel(plan: manager.currentPlan);
  }

  Future<void> setPlan(UserPlan plan) async {
    state = UserModel(plan: plan);
  }

  Future<void> refreshFromPremium() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final billing = ref.read(billingServiceProvider);
    final manager = PremiumManager(prefs, billing);
    state = UserModel(plan: manager.currentPlan);
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel>(
  CurrentUserNotifier.new,
);
