String formatAmount(String symbol, double amount) {
  // Symbols that need a space after them (prefix symbols like Br, ₽ etc.)
  const spaceAfter = {'Br', '₽'};
  final formatted = amount.toStringAsFixed(2);
  if (spaceAfter.contains(symbol)) {
    return '$symbol $formatted';
  }
  return '$symbol$formatted';
}
