import 'package:flutter/material.dart';
import '../../../shared/widgets/byn_sign.dart';

class CurrencyPicker extends StatelessWidget {
  final String selected;
  final void Function(String symbol, String code) onChanged;

  const CurrencyPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = [
      ('USD', '\$'),
      ('EUR', '€'),
      ('BYN', 'Br'),
      ('RUB', '₽'),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: currencies.map((c) {
        final isSelected = c.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(c.$2, c.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: c.$1 == currencies.last.$1 ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C6DED).withOpacity(0.15)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C6DED)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  c.$1 == 'BYN'
                      ? BynSign(
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFF7C6DED)
                              : colorScheme.onSurface,
                        )
                      : Text(
                          c.$2,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF7C6DED)
                                : colorScheme.onSurface,
                          ),
                        ),
                  Text(
                    c.$1,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
