import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../shared/widgets/byn_sign.dart';
import '../provider.dart';

class CurrencySection extends ConsumerWidget {
  const CurrencySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currencyInfo = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.currency,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['USD', 'EUR', 'BYN', 'RUB'].map((code) {
              final info = currencyMap[code]!;
              final isSelected = currencyInfo.code == code;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(currencyProvider.notifier).setCurrency(code);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withOpacity(0.2)
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.accent, width: 1.5)
                            : (isDark
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFDDDDEE),
                                      width: 1,
                                    )),
                      ),
                      child: Column(
                        children: [
                          code == 'BYN'
                              ? SizedBox(
                                  height: 28,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: BynSign(
                                      fontSize: 24,
                                      color: isSelected
                                          ? AppColors.accent
                                          : Theme.of(context).colorScheme.onSurface
                                                .withOpacity(0.6),
                                    ),
                                  ),
                                )
                              : Text(
                                  info.symbol,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: isSelected
                                            ? AppColors.accent
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                ),
                          const SizedBox(height: 2),
                          Text(
                            code,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? AppColors.accent
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.6),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
