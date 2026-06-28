import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/providers/current_user_provider.dart';
import '../../../shared/models/user_model.dart';

class PremiumSection extends ConsumerWidget {
  const PremiumSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: const Color(0xFFDDDDEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (user.isVip ? AppColors.accent : AppColors.warning)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  user.isVip ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                  color: user.isVip ? AppColors.accent : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.premiumStatus,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      s.premiumDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: user.isVip,
                onChanged: (value) async {
                  HapticService.light();
                  await ref.read(currentUserProvider.notifier).setPlan(
                        value ? UserPlan.vip : UserPlan.free,
                      );
                },
                activeThumbColor: const Color(0xFF7C6DED),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
