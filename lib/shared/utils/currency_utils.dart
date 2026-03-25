import '../../core/constants.dart';

String formatAmount(String symbol, double amount, AmountFormat fmt) {
  final formatted = fmt.format(amount);
  if (symbol.isEmpty) return formatted;
  return '$symbol$formatted';
}
