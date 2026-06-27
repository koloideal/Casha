import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/utils/result.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/category_repository.dart';
import '../../features/dashboard/provider.dart';
import '../models/app_category.dart';
import '../models/transaction.dart';
import '../services/translation_service.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(appDatabaseProvider));
});

final customCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  return CategoryActions(ref);
});

class CategoryActions {
  final Ref _ref;

  CategoryActions(this._ref);

  CategoryRepository get _repo => _ref.read(categoryRepositoryProvider);

  Future<Result<void>> create({
    required TransactionType type,
    required String labelEn,
    required String labelRu,
    required String iconName,
    required int colorValue,
  }) {
    return asyncResultOf(() async {
      final en = labelEn.trim();
      final ru = labelRu.trim();
      if (en.isEmpty && ru.isEmpty) {
        throw Exception('Category name is required');
      }
      final key = 'cat_${DateTime.now().microsecondsSinceEpoch}';
      await _repo.add(
        name: key,
        type: type.name,
        labelEn: en.isEmpty ? ru : en,
        labelRu: ru.isEmpty ? en : ru,
        iconName: iconName,
        colorValue: colorValue,
      );
    });
  }

  Future<Result<void>> edit({
    required int id,
    required TransactionType type,
    required String labelEn,
    required String labelRu,
    required String iconName,
    required int colorValue,
  }) {
    return asyncResultOf(() async {
      final en = labelEn.trim();
      final ru = labelRu.trim();
      if (en.isEmpty && ru.isEmpty) {
        throw Exception('Category name is required');
      }
      await _repo.updateFields(
        id,
        type: type.name,
        labelEn: en.isEmpty ? ru : en,
        labelRu: ru.isEmpty ? en : ru,
        iconName: iconName,
        colorValue: colorValue,
      );
    });
  }

  Future<Result<void>> remove(int id) {
    return asyncResultOf(() async {
      await _repo.delete(id);
    });
  }
}

class CategoryCatalog {
  final List<AppCategory> all;

  const CategoryCatalog(this.all);

  List<AppCategory> forType(TransactionType type) =>
      all.where((c) => c.type == type).toList();

  List<AppCategory> get custom => all.where((c) => c.isCustom).toList();

  AppCategory? byKey(String key) =>
      all.firstWhereOrNull((c) => c.key == key);

  IconData iconFor(String key) =>
      byKey(key)?.icon ?? Icons.category_rounded;

  Color colorFor(String key, [Color? fallback]) =>
      byKey(key)?.color ?? fallback ?? AppColors.accent;

  String labelFor(String key, bool isRu) =>
      byKey(key)?.label(isRu) ?? key;

  bool hasKey(String key) => byKey(key) != null;
}

final categoryCatalogProvider = Provider<CategoryCatalog>((ref) {
  final custom = ref.watch(customCategoriesProvider).value ?? const [];
  final mapped = custom.map(_fromRow).toList();
  return CategoryCatalog([..._defaultCategories(), ...mapped]);
});

List<AppCategory> _defaultCategories() {
  final result = <AppCategory>[];
  for (final key in AppCategories.expenseCategories) {
    result.add(_defaultCategory(key, TransactionType.expense));
  }
  for (final key in AppCategories.incomeCategories) {
    result.add(_defaultCategory(key, TransactionType.income));
  }
  return result;
}

AppCategory _defaultCategory(String key, TransactionType type) {
  final iconName = AppCategories.iconNames[key] ?? 'category';
  return AppCategory(
    key: key,
    type: type,
    labelEn: key,
    labelRu: AppCategories.ruLabels[key] ?? key,
    icon: categoryIconByName(iconName),
    color: AppCategories.colors[key] ?? AppColors.accent,
    iconName: iconName,
    isCustom: false,
  );
}

AppCategory _fromRow(Category row) {
  final type =
      row.type == 'income' ? TransactionType.income : TransactionType.expense;
  final labelEn = (row.labelEn != null && row.labelEn!.isNotEmpty)
      ? row.labelEn!
      : row.name;
  final labelRu = (row.labelRu != null && row.labelRu!.isNotEmpty)
      ? row.labelRu!
      : row.name;
  final colorValue = int.tryParse(row.color ?? '');
  final color = colorValue != null
      ? Color(colorValue)
      : kCategoryColors[row.id % kCategoryColors.length];
  return AppCategory(
    key: row.name,
    type: type,
    labelEn: labelEn,
    labelRu: labelRu,
    icon: categoryIconByName(row.icon),
    color: color,
    iconName: row.icon ?? 'category',
    isCustom: true,
    id: row.id,
  );
}
