import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  final String label;
  final String dateLocale;
  final bool isDark;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onTap,
    required this.label,
    required this.dateLocale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isDark
                  ? null
                  : Border.all(color: const Color(0xFFCCCCDD), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy', dateLocale).format(selectedDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TimePickerField extends StatelessWidget {
  final TimeOfDay selectedTime;
  final VoidCallback onTap;
  final String label;
  final bool isDark;

  const TimePickerField({
    super.key,
    required this.selectedTime,
    required this.onTap,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isDark
                  ? null
                  : Border.all(color: const Color(0xFFCCCCDD), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedTime.format(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
