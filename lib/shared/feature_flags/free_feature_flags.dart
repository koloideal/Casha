import 'feature_flags.dart';

class FreeFeatureFlags implements FeatureFlags {
  const FreeFeatureFlags();

  @override
  bool get canEditCardColors => false;

  @override
  bool get canEditCardHeight => false;

  @override
  bool get canEditCardTextColor => false;

  @override
  int get maxAccounts => 3;
}
