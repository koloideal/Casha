import 'dart:convert';
import 'package:http/http.dart' as http;

enum TranslateDirection { ruToEn, enToRu }

class TranslationResult {
  final String text;
  final bool fromCache;

  const TranslationResult(this.text, {this.fromCache = false});
}

class TranslationService {
  static const Map<String, String> _ruToEn = {
    'еда': 'Food',
    'продукты': 'Groceries',
    'транспорт': 'Transport',
    'покупки': 'Shopping',
    'здоровье': 'Health',
    'развлечения': 'Entertainment',
    'жильё': 'Housing',
    'жилье': 'Housing',
    'аренда': 'Rent',
    'образование': 'Education',
    'путешествия': 'Travel',
    'зарплата': 'Salary',
    'фриланс': 'Freelance',
    'инвестиции': 'Investment',
    'подарок': 'Gift',
    'подарки': 'Gifts',
    'возврат': 'Refund',
    'другое': 'Other',
    'коммунальные': 'Utilities',
    'одежда': 'Clothing',
    'спорт': 'Sports',
    'красота': 'Beauty',
    'питомцы': 'Pets',
    'животные': 'Pets',
    'бизнес': 'Business',
    'накопления': 'Savings',
    'кафе': 'Cafe',
    'кофе': 'Coffee',
    'ресторан': 'Restaurant',
    'связь': 'Communication',
    'интернет': 'Internet',
    'налоги': 'Taxes',
    'страховка': 'Insurance',
    'медицина': 'Medicine',
    'дети': 'Children',
    'хобби': 'Hobby',
    'музыка': 'Music',
    'игры': 'Games',
    'книги': 'Books',
    'топливо': 'Fuel',
    'такси': 'Taxi',
  };

  static final Map<String, String> _enToRu = {
    for (final entry in _ruToEn.entries) entry.value.toLowerCase(): entry.key,
  };

  String? dictionaryLookup(String input, TranslateDirection direction) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final map = direction == TranslateDirection.ruToEn ? _ruToEn : _enToRu;
    final hit = map[normalized];
    if (hit == null) return null;
    return _capitalize(hit);
  }

  Future<TranslationResult?> translate(
    String input,
    TranslateDirection direction,
  ) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final cached = dictionaryLookup(trimmed, direction);
    if (cached != null) {
      return TranslationResult(cached, fromCache: true);
    }

    final pair = direction == TranslateDirection.ruToEn ? 'ru|en' : 'en|ru';
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get'
      '?q=${Uri.encodeQueryComponent(trimmed)}&langpair=$pair',
    );

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['responseData'] as Map<String, dynamic>?;
      final translated = data?['translatedText'] as String?;
      if (translated == null || translated.trim().isEmpty) return null;
      return TranslationResult(_capitalize(translated.trim()));
    } catch (_) {
      return null;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
