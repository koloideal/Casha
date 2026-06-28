enum UserPlan { free, vip }

class UserModel {
  final UserPlan plan;

  const UserModel({this.plan = UserPlan.free});

  bool get isVip => plan == UserPlan.vip;
}
