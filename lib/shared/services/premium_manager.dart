import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'billing_service.dart';

class PremiumManager {
  static const _keyIsPremium = 'is_premium';
  static const _keyPurchaseToken = 'purchase_token';

  final SharedPreferences _prefs;
  final BillingService _billing;

  PremiumManager(this._prefs, this._billing);

  bool get isPremium => _prefs.getBool(_keyIsPremium) ?? false;
  String? get purchaseToken => _prefs.getString(_keyPurchaseToken);

  Future<void> _setPremium(bool value, String? token) async {
    await _prefs.setBool(_keyIsPremium, value);
    if (token != null) {
      await _prefs.setString(_keyPurchaseToken, token);
    } else if (!value) {
      await _prefs.remove(_keyPurchaseToken);
    }
  }

  Future<PurchaseResult> purchase() async {
    final result = await _billing.purchasePro();
    if (result.success && result.purchaseToken != null) {
      await _setPremium(true, result.purchaseToken);
      await _billing.completePurchase(result.purchaseToken!);
    }
    return result;
  }

  Future<PurchaseResult> restore() async {
    final result = await _billing.restorePurchases();
    if (result.success && result.purchaseToken != null) {
      await _setPremium(true, result.purchaseToken);
      await _billing.completePurchase(result.purchaseToken!);
    }
    return result;
  }

  Future<void> autoRestore() async {
    if (isPremium) return;
    final result = await _billing.queryPastPurchase();
    if (result.success && result.purchaseToken != null) {
      await _setPremium(true, result.purchaseToken);
      await _billing.completePurchase(result.purchaseToken!);
    }
  }

  UserPlan get currentPlan => isPremium ? UserPlan.vip : UserPlan.free;

  Future<void> clear() async {
    await _setPremium(false, null);
  }
}
