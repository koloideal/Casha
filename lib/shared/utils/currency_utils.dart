import '../../core/constants.dart';

String formatAmount(String symbol, double amount, AmountFormat fmt) {
  const spaceAfter = {'Br'};
  final formatted = fmt.format(amount);
  // For BYN, symbol is empty string, so we use 'Br' for text-only contexts like CSV
  final displaySymbol = symbol.isEmpty ? 'Br' : symbol;
  final sep = spaceAfter.contains(displaySymbol) ? ' ' : '';
  return '$displaySymbol$sep$formatted';
}
