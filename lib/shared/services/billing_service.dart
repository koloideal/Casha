import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseResult {
  final bool success;
  final String? purchaseToken;
  final String? error;

  const PurchaseResult({this.success = false, this.purchaseToken, this.error});

  factory PurchaseResult.ok(String token) =>
      PurchaseResult(success: true, purchaseToken: token);

  factory PurchaseResult.failed([String? error]) =>
      PurchaseResult(success: false, error: error);
}

abstract class BillingService {
  static const proProductId = 'casha_pro_lifetime';

  Future<PurchaseResult> purchasePro();
  Future<PurchaseResult> restorePurchases();
  Future<PurchaseResult> queryPastPurchase();
  Future<void> completePurchase(String purchaseToken);
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<void> dispose();
}

class PlayBillingService implements BillingService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  PlayBillingService() {
    _sub = _inAppPurchase.purchaseStream.listen((purchases) {
      _controller.add(purchases);
    });
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<PurchaseResult> purchasePro() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return PurchaseResult.failed('Billing not available');
    }

    final response = await _inAppPurchase.queryProductDetails(
      {BillingService.proProductId},
    );
    if (response.productDetails.isEmpty) {
      return PurchaseResult.failed('Product not found');
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!started) {
      return PurchaseResult.failed('Could not start purchase');
    }

    final completer = Completer<PurchaseResult>();
    late StreamSubscription sub;
    sub = purchaseStream.timeout(
      const Duration(seconds: 60),
      onTimeout: (sink) {
        if (!completer.isCompleted) {
          completer.complete(PurchaseResult.failed('Purchase timed out'));
        }
        sub.cancel();
      },
    ).listen((purchases) {
      for (final p in purchases) {
        if (p.productID == BillingService.proProductId &&
            p.status == PurchaseStatus.purchased) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseResult.ok(p.verificationData.serverVerificationData));
          }
          sub.cancel();
          return;
        }
        if (p.status == PurchaseStatus.error) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseResult.failed(p.error?.message));
          }
          sub.cancel();
          return;
        }
      }
    });

    return completer.future;
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return PurchaseResult.failed('Billing not available');
    }

    await _inAppPurchase.restorePurchases();

    final completer = Completer<PurchaseResult>();
    late StreamSubscription sub;
    sub = purchaseStream.timeout(
      const Duration(seconds: 15),
      onTimeout: (sink) {
        if (!completer.isCompleted) {
          completer.complete(PurchaseResult.failed('Restore timed out'));
        }
        sub.cancel();
      },
    ).listen((purchases) {
      for (final p in purchases) {
        if (p.productID == BillingService.proProductId &&
            (p.status == PurchaseStatus.restored ||
                p.status == PurchaseStatus.purchased)) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseResult.ok(p.verificationData.serverVerificationData));
          }
          sub.cancel();
          return;
        }
      }
    });

    return completer.future;
  }

  @override
  Future<PurchaseResult> queryPastPurchase() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const PurchaseResult();
    }

    final response = await _inAppPurchase.queryProductDetails(
      {BillingService.proProductId},
    );
    if (response.productDetails.isEmpty) {
      return const PurchaseResult();
    }

    final completer = Completer<PurchaseResult>();
    late StreamSubscription sub;
    sub = purchaseStream.timeout(
      const Duration(seconds: 10),
      onTimeout: (sink) {
        if (!completer.isCompleted) {
          completer.complete(const PurchaseResult());
        }
        sub.cancel();
      },
    ).listen((purchases) {
      for (final p in purchases) {
        if (p.productID == BillingService.proProductId &&
            (p.status == PurchaseStatus.restored ||
                p.status == PurchaseStatus.purchased)) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseResult.ok(p.verificationData.serverVerificationData));
          }
          sub.cancel();
          return;
        }
      }
    });

    await _inAppPurchase.restorePurchases();

    return completer.future;
  }

  @override
  Future<void> completePurchase(String purchaseToken) async {
    if (kDebugMode) {
      print('completePurchase: $purchaseToken');
    }
  }

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await _controller.close();
  }
}

class DebugBillingService implements BillingService {
  static const _key = 'debug_purchase_token';
  final SharedPreferences _prefs;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  DebugBillingService(this._prefs);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<PurchaseResult> purchasePro() async {
    await Future.delayed(const Duration(seconds: 1));
    final token = 'debug_token_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString(_key, token);
    return PurchaseResult.ok(token);
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    await Future.delayed(const Duration(seconds: 1));
    final token = _prefs.getString(_key);
    if (token != null) {
      return PurchaseResult.ok(token);
    }
    return const PurchaseResult();
  }

  @override
  Future<PurchaseResult> queryPastPurchase() async {
    final token = _prefs.getString(_key);
    if (token != null) {
      return PurchaseResult.ok(token);
    }
    return const PurchaseResult();
  }

  @override
  Future<void> completePurchase(String purchaseToken) async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
