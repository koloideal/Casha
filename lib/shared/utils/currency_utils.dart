import '../../core/constants.dart';

String formatAmount(String symbol, double amount, AmountFormat fmt) {
  const spaceAfter = {'Br'};
  final formatted = fmt.format(amount);
  final sep = spaceAfter.contains(symbol) ? ' ' : '';
  return '$symbol$sep$formatted';
}
