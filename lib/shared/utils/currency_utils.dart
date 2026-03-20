import '../../core/constants.dart';

String formatAmount(String symbol, double amount, AmountFormat fmt) {
  // Symbols that need a space after them (prefix symbols like Br, ₽ etc.)
  const spaceAfter = {'Br', '₽'};
  final formatted = fmt.format(amount);
  final sep = spaceAfter.contains(symbol) ? ' ' : '';
  return '$symbol$sep$formatted';
}
