import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/provider.dart';
import '../models/user_model.dart';

class CurrentUserNotifier extends Notifier<UserModel> {
  static const _key = 'user_plan';

  @override
  UserModel build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final planName = prefs.getString(_key);
    final plan = UserPlan.values.firstWhere(
      (e) => e.name == planName,
      orElse: () => UserPlan.free,
    );
    return UserModel(plan: plan);
  }

  Future<void> setPlan(UserPlan plan) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = UserModel(plan: plan);
    await prefs.setString(_key, plan.name);
  }

  Future<void> toggleVip() async {
    await setPlan(state.isVip ? UserPlan.free : UserPlan.vip);
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel>(
  CurrentUserNotifier.new,
);
