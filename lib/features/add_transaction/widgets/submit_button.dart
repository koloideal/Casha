import 'package:flutter/material.dart';
import '../../../shared/models/transaction.dart';

class SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final bool isEditing;
  final TransactionType type;
  final VoidCallback onPressed;
  final String saveChangesText;
  final String addTransactionText;

  const SubmitButton({
    super.key,
    required this.isSubmitting,
    required this.isEditing,
    required this.type,
    required this.onPressed,
    required this.saveChangesText,
    required this.addTransactionText,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = type == TransactionType.income
        ? const Color(0xFF4CAF8C)
        : const Color(0xFFE05C6B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isSubmitting ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: typeColor.withOpacity(0.1),
            side: BorderSide(color: typeColor, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            foregroundColor: typeColor,
          ),
          child: isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: typeColor,
                  ),
                )
              : Text(
                  isEditing ? saveChangesText : addTransactionText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
        ),
      ),
    );
  }
}
