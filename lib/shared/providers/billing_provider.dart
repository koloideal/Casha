import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/provider.dart';
import '../services/billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MockBillingService(prefs);
});
