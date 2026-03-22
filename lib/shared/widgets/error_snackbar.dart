import 'package:flutter/material.dart';
import '../../core/utils/result.dart';

/// Show error snackbar with custom styling
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
        ],
      ),
      backgroundColor: const Color(0xFFE05C6B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// Show success snackbar with custom styling
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
        ],
      ),
      backgroundColor: const Color(0xFF4CAF8C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Show warning snackbar with custom styling
void showWarningSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
        ],
      ),
      backgroundColor: const Color(0xFFFFB74D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Extension to handle Result with UI feedback
extension ResultUIExtension<T> on Result<T> {
  /// Show snackbar on failure
  Result<T> showErrorOnFailure(BuildContext context) {
    onFailure((message) => showErrorSnackbar(context, message));
    return this;
  }

  /// Show snackbar on success with custom message
  Result<T> showSuccessMessage(BuildContext context, String message) {
    onSuccess((_) => showSuccessSnackbar(context, message));
    return this;
  }
}

/// Extension for Future<Result<T>>
extension FutureResultUIExtension<T> on Future<Result<T>> {
  /// Show snackbar on failure
  Future<Result<T>> showErrorOnFailure(BuildContext context) async {
    final result = await this;
    result.onFailure((message) => showErrorSnackbar(context, message));
    return result;
  }

  /// Show snackbar on success with custom message
  Future<Result<T>> showSuccessMessage(
    BuildContext context,
    String message,
  ) async {
    final result = await this;
    result.onSuccess((_) => showSuccessSnackbar(context, message));
    return result;
  }

  /// Show both success and error messages
  Future<Result<T>> showFeedback(
    BuildContext context, {
    required String successMessage,
  }) async {
    final result = await this;
    result
        .onSuccess((_) => showSuccessSnackbar(context, successMessage))
        .onFailure((message) => showErrorSnackbar(context, message));
    return result;
  }
}

/// Error dialog widget
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE05C6B), size: 28),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          ErrorDialog(title: title, message: message, onRetry: onRetry),
    );
  }
}
