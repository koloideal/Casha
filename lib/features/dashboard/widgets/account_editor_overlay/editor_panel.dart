import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/byn_sign.dart';

class AccountEditorPanel extends ConsumerWidget {
  final TextEditingController nameController;
  final String selectedCurrency;
  final bool showCurrencyDropdown;
  final bool showLimitError;
  final bool showDuplicateError;
  final VoidCallback onCurrencyDropdownToggle;
  final BuildContext dashboardContext;
  final double panelHeight;

  const AccountEditorPanel({
    super.key,
    required this.nameController,
    required this.selectedCurrency,
    required this.showCurrencyDropdown,
    required this.showLimitError,
    required this.showDuplicateError,
    required this.onCurrencyDropdownToggle,
    required this.dashboardContext,
    required this.panelHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        color: Theme.of(dashboardContext).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            dashboardContext,
          ).colorScheme.onSurface.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  dashboardContext,
                ).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: nameController,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Account name',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            dashboardContext,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          dashboardContext,
                        ).colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                (showLimitError ||
                                    showDuplicateError ||
                                    nameController.text.trim().isEmpty)
                                ? Colors.red
                                : Theme.of(
                                    dashboardContext,
                                  ).colorScheme.onSurface.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                (showLimitError ||
                                    showDuplicateError ||
                                    nameController.text.trim().isEmpty)
                                ? Colors.red
                                : Theme.of(
                                    dashboardContext,
                                  ).colorScheme.onSurface.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                (showLimitError ||
                                    showDuplicateError ||
                                    nameController.text.trim().isEmpty)
                                ? Colors.red
                                : const Color(0xFF7C6DED),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onCurrencyDropdownToggle,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            dashboardContext,
                          ).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: showCurrencyDropdown
                                ? const Color(0xFF7C6DED)
                                : Theme.of(
                                    dashboardContext,
                                  ).colorScheme.onSurface.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            selectedCurrency == 'BYN'
                                ? BynSign(
                                    fontSize: 15,
                                    color: Theme.of(
                                      dashboardContext,
                                    ).colorScheme.onSurface,
                                  )
                                : Text(
                                    [
                                          ('USD', '\$'),
                                          ('EUR', '€'),
                                          ('BYN', 'Br'),
                                          ('RUB', '₽'),
                                        ]
                                        .firstWhere(
                                          (c) => c.$1 == selectedCurrency,
                                        )
                                        .$2,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            const SizedBox(width: 4),
                            Icon(
                              showCurrencyDropdown
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 20,
                              color: Theme.of(
                                dashboardContext,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
