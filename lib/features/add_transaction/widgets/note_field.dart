import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoteField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const NoteField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      maxLength: 20,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              Text(
                '$currentLength/$maxLength',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
      decoration: InputDecoration(
        hintText: hintText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFCCCCDD), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C6DED), width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
