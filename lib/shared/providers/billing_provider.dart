import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  return PlayBillingService();
});
