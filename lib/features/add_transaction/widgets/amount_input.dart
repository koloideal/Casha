import 'package:flutter/material.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final bool showError;
  final Animation<Color?> borderColorAnimation;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const AmountInput({
    super.key,
    required this.controller,
    required this.currencySymbol,
    required this.showError,
    required this.borderColorAnimation,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: borderColorAnimation,
      builder: (context, child) {
        final isError = showError;
        final normalBorder = isDark
            ? Colors.transparent
            : const Color(0xFFCCCCDD);
        final borderColor = isError
            ? (borderColorAnimation.value ?? const Color(0xFFE05C6B))
            : normalBorder;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isError ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  currencySymbol,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
