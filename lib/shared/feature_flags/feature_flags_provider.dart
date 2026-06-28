import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/current_user_provider.dart';
import 'feature_flags.dart';
import 'free_feature_flags.dart';
import 'vip_feature_flags.dart';

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.isVip
      ? const VipFeatureFlags()
      : const FreeFeatureFlags();
});
