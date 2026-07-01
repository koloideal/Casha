import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../provider.dart';

class CardTextColorSection extends ConsumerWidget {
  const CardTextColorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final textColorMode = ref.watch(cardTextColorProvider);
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
                  color: const Color(0xFF7C6DED).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.text_fields_rounded,
                  color: const Color(0xFF7C6DED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                s.cardTextColor,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardTextColorOption(
                  label: s.cardTextColorWhite,
                  icon: Icons.brightness_high_rounded,
                  isSelected: textColorMode == CardTextColorMode.white,
                  onTap: () => ref
                      .read(cardTextColorProvider.notifier)
                      .set(CardTextColorMode.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardTextColorOption(
                  label: s.cardTextColorAdaptive,
                  icon: Icons.auto_awesome_rounded,
                  isSelected: textColorMode == CardTextColorMode.adaptive,
                  onTap: () => ref
                      .read(cardTextColorProvider.notifier)
                      .set(CardTextColorMode.adaptive),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardTextColorOption(
                  label: s.cardTextColorBlack,
                  icon: Icons.brightness_low_rounded,
                  isSelected: textColorMode == CardTextColorMode.black,
                  onTap: () => ref
                      .read(cardTextColorProvider.notifier)
                      .set(CardTextColorMode.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardTextColorOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardTextColorOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C6DED).withOpacity(0.15)
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C6DED)
                : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF7C6DED)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF7C6DED)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
