import 'package:flutter/material.dart';
import '../shared/models/transaction.dart';

class AppColors {
  static const background = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const accent = Color(0xFF7C6DED);
  static const income = Color(0xFF4CAF8C);
  static const expense = Color(0xFFE05C6B);
  static const textPrimary = Color(0xFFEEEEF5);
  static const textSecondary = Color(0xFF8888A0);
  static const divider = Color(0xFF2A2A38);
  static const warning = Color(0xFFFFB74D);

  static const lightBackground = Color(0xFFF5F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF1A1A24);
  static const lightTextSecondary = Color(0xFF6B6B80);
  static const lightDivider = Color(0xFFE0E0E8);
}

class AppCategories {
  static const expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Entertainment',
    'Housing',
    'Education',
    'Travel',
    'Utilities',
    'Clothing',
    'Sports',
    'Beauty',
    'Pets',
    'Other'
  ];

  static const incomeCategories = [
    'Salary',
    'Freelance',
    'Gift',
    'Investment',
    'Refund',
    'Business',
    'Savings',
    'Other'
  ];

  static List<String> forType(TransactionType type) {
    return type == TransactionType.expense
        ? expenseCategories
        : incomeCategories;
  }

  static const icons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Health': Icons.favorite_rounded,
    'Entertainment': Icons.movie_rounded,
    'Housing': Icons.home_rounded,
    'Education': Icons.school_rounded,
    'Travel': Icons.flight_rounded,
    'Utilities': Icons.bolt_rounded,
    'Clothing': Icons.checkroom_rounded,
    'Sports': Icons.fitness_center_rounded,
    'Beauty': Icons.brush_rounded,
    'Pets': Icons.pets_rounded,
    'Salary': Icons.work_rounded,
    'Freelance': Icons.laptop_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Investment': Icons.trending_up_rounded,
    'Refund': Icons.money_rounded,
    'Business': Icons.business_center_rounded,
    'Savings': Icons.savings_rounded,
    'Other': Icons.category_rounded,
  };

  static const colors = {
    'Food': Color(0xFFFF8C69),
    'Transport': Color(0xFF69B4FF),
    'Shopping': Color(0xFFFFD369),
    'Health': Color(0xFF69FFB4),
    'Entertainment': Color(0xFFFF69B4),
    'Housing': Color(0xFF69B4FF),
    'Education': Color(0xFFFFB469),
    'Travel': Color(0xFF69FFB4),
    'Utilities': Color(0xFFFFD369),
    'Clothing': Color(0xFFFF69B4),
    'Sports': Color(0xFF69FFB4),
    'Beauty': Color(0xFFFF69B4),
    'Pets': Color(0xFFB4FF69),
    'Salary': Color(0xFF4CAF8C),
    'Freelance': Color(0xFF69FFB4),
    'Gift': Color(0xFFFFB469),
    'Investment': Color(0xFF69B4FF),
    'Refund': Color(0xFFB4FF69),
    'Business': Color(0xFFFF8C69),
    'Savings': Color(0xFF4CAF8C),
    'Other': Color(0xFFB469FF),
  };

  static const iconNames = {
    'Food': 'restaurant',
    'Transport': 'car',
    'Shopping': 'shopping_bag',
    'Health': 'heart',
    'Entertainment': 'movie',
    'Housing': 'home',
    'Education': 'school',
    'Travel': 'flight',
    'Utilities': 'bolt',
    'Clothing': 'checkroom',
    'Sports': 'fitness',
    'Beauty': 'brush',
    'Pets': 'pets',
    'Salary': 'work',
    'Freelance': 'laptop',
    'Gift': 'gift',
    'Investment': 'trending_up',
    'Refund': 'money',
    'Business': 'work',
    'Savings': 'savings',
    'Other': 'category',
  };

  static const ruLabels = {
    'Food': 'Еда',
    'Transport': 'Транспорт',
    'Shopping': 'Покупки',
    'Entertainment': 'Развлечения',
    'Health': 'Здоровье',
    'Housing': 'Жильё',
    'Education': 'Образование',
    'Travel': 'Путешествия',
    'Salary': 'Зарплата',
    'Freelance': 'Фриланс',
    'Investment': 'Инвестиции',
    'Gift': 'Подарок',
    'Refund': 'Возврат',
    'Other': 'Другое',
    'Utilities': 'Коммунальные',
    'Clothing': 'Одежда',
    'Sports': 'Спорт',
    'Beauty': 'Красота',
    'Pets': 'Питомцы',
    'Business': 'Бизнес',
    'Savings': 'Накопления',
    'Dining': 'Ресторан',
    'Cafe': 'Кафе',
    'Coffee': 'Кофе',
    'Restaurant': 'Ресторан',
    'Fuel': 'Топливо',
    'Taxi': 'Такси',
    'Phone': 'Связь',
    'Internet': 'Интернет',
    'Insurance': 'Страховка',
    'Taxes': 'Налоги',
    'Medicine': 'Медицина',
    'Children': 'Дети',
    'Hobby': 'Хобби',
    'Music': 'Музыка',
    'Games': 'Игры',
    'Books': 'Книги',
  };
}

const Map<String, IconData> kCategoryIcons = {
  'restaurant': Icons.restaurant_rounded,
  'car': Icons.directions_car_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'heart': Icons.favorite_rounded,
  'movie': Icons.movie_rounded,
  'work': Icons.work_rounded,
  'laptop': Icons.laptop_rounded,
  'gift': Icons.card_giftcard_rounded,
  'trending_up': Icons.trending_up_rounded,
  'money': Icons.payments_rounded,
  'category': Icons.category_rounded,
  'home': Icons.home_rounded,
  'school': Icons.school_rounded,
  'flight': Icons.flight_rounded,
  'fitness': Icons.fitness_center_rounded,
  'pets': Icons.pets_rounded,
  'coffee': Icons.local_cafe_rounded,
  'grocery': Icons.local_grocery_store_rounded,
  'phone': Icons.smartphone_rounded,
  'bolt': Icons.bolt_rounded,
  'water': Icons.water_drop_rounded,
  'savings': Icons.savings_rounded,
  'card': Icons.credit_card_rounded,
  'games': Icons.sports_esports_rounded,
  'music': Icons.music_note_rounded,
  'book': Icons.menu_book_rounded,
  'medical': Icons.medical_services_rounded,
  'child': Icons.child_care_rounded,
  'build': Icons.build_rounded,
  'beauty': Icons.spa_rounded,
};

IconData categoryIconByName(String? name) {
  return kCategoryIcons[name] ?? Icons.category_rounded;
}

const List<Color> kCategoryColors = [
  Color(0xFFFF8C69),
  Color(0xFF69B4FF),
  Color(0xFFFFD369),
  Color(0xFF69FFB4),
  Color(0xFFFF69B4),
  Color(0xFF4CAF8C),
  Color(0xFFFFB469),
  Color(0xFFB4FF69),
  Color(0xFFB469FF),
  Color(0xFF7C6DED),
  Color(0xFFE05C6B),
  Color(0xFF4DD0E1),
];

enum AmountFormat { commasDot, spacesDot, plain }

extension AmountFormatExt on AmountFormat {
  String get label {
    switch (this) {
      case AmountFormat.commasDot: return '1,234,567.89';
      case AmountFormat.spacesDot: return '1 234 567.89';
      case AmountFormat.plain:     return '1234567.89';
    }
  }

  String get example {
    switch (this) {
      case AmountFormat.commasDot: return 'SYM 1,234.56';
      case AmountFormat.spacesDot: return 'SYM 1 234.56';
      case AmountFormat.plain:     return 'SYM 1234.56';
    }
  }

  String format(double amount) {
    switch (this) {
      case AmountFormat.commasDot:
        final parts = amount.toStringAsFixed(2).split('.');
        final intPart = parts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
        return '$intPart.${parts[1]}';
      case AmountFormat.spacesDot:
        final parts = amount.toStringAsFixed(2).split('.');
        final intPart = parts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
        return '$intPart.${parts[1]}';
      case AmountFormat.plain:
        return amount.toStringAsFixed(2);
    }
  }
}

class CurrencyOption {
  final String symbol;
  final String name;
  final String code;

  const CurrencyOption({
    required this.symbol,
    required this.name,
    required this.code,
  });
}

class AppCurrencies {
  static const options = [
    CurrencyOption(symbol: '\$', name: 'US Dollar', code: 'USD'),
    CurrencyOption(symbol: '€', name: 'Euro', code: 'EUR'),
    CurrencyOption(symbol: '£', name: 'British Pound', code: 'GBP'),
    CurrencyOption(symbol: '', name: 'Belarusian Ruble', code: 'BYN'),
    CurrencyOption(symbol: '₽', name: 'Russian Ruble', code: 'RUB'),
    CurrencyOption(symbol: '₴', name: 'Ukrainian Hryvnia', code: 'UAH'),
  ];

  static CurrencyOption findBySymbol(String symbol) {
    return options.firstWhere(
      (c) => c.symbol == symbol,
      orElse: () => options.first,
    );
  }
}

const List<(String, String)> kDisplayCurrencies = [
  ('USD', r'$'),
  ('EUR', '€'),
  ('BYN', ''),
  ('RUB', '₽'),
];
