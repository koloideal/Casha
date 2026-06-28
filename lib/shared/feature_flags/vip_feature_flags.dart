import 'feature_flags.dart';

class VipFeatureFlags implements FeatureFlags {
  const VipFeatureFlags();

  @override
  bool get canEditCardColors => true;

  @override
  bool get canEditCardHeight => true;

  @override
  bool get canEditCardTextColor => true;

  @override
  int get maxAccounts => 8;
}
