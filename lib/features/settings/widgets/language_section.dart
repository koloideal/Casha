import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';

class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currentLocale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1),
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
                  Icons.language_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.en),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: currentLocale == AppLocale.en
                          ? AppColors.accent.withOpacity(0.2)
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: currentLocale == AppLocale.en
                          ? Border.all(color: AppColors.accent, width: 1.5)
                          : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
                    ),
                    child: Text(
                      s.langEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: currentLocale == AppLocale.en
                            ? AppColors.accent
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: currentLocale == AppLocale.en ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.ru),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: currentLocale == AppLocale.ru
                          ? AppColors.accent.withOpacity(0.2)
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: currentLocale == AppLocale.ru
                          ? Border.all(color: AppColors.accent, width: 1.5)
                          : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
                    ),
                    child: Text(
                      s.langRu,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: currentLocale == AppLocale.ru
                            ? AppColors.accent
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: currentLocale == AppLocale.ru ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
