import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class BillingService {
  Future<bool> purchasePro();
  Future<bool> restorePurchases();
  Future<UserPlan> getCurrentPlan();
}

class MockBillingService implements BillingService {
  static const _key = 'user_plan';
  final SharedPreferences _prefs;

  MockBillingService(this._prefs);

  @override
  Future<bool> purchasePro() async {
    await Future.delayed(const Duration(seconds: 1));
    await _prefs.setString(_key, 'vip');
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(seconds: 1));
    return false;
  }

  @override
  Future<UserPlan> getCurrentPlan() async {
    final value = _prefs.getString(_key);
    return value == 'vip' ? UserPlan.vip : UserPlan.free;
  }
}
