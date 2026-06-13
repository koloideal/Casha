import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class AmountFormatNotifier extends Notifier<AmountFormat> {
  @override
  AmountFormat build() {
    _load();
    return AmountFormat.commasDot;
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('amount_format') ?? 0;
    state = AmountFormat.values[index];
  }

  void set(AmountFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    state = format;
    await prefs.setInt('amount_format', format.index);
  }
}

final amountFormatProvider = NotifierProvider<AmountFormatNotifier, AmountFormat>(
  AmountFormatNotifier.new,
);
