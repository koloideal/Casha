import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paywall_banner.dart';

class PaywallGuard extends ConsumerWidget {
  final bool canAccess;
  final Widget child;
  final Widget? fallback;

  const PaywallGuard({
    super.key,
    required this.canAccess,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (canAccess) return child;
    return fallback ?? PaywallBanner();
  }
}
