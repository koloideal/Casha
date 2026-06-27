import 'package:drift/drift.dart';
import '../database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Stream<List<Category>> watchAll() {
    return _db.watchAllCategories();
  }

  Future<List<Category>> getAll() {
    return _db.getAllCategories();
  }

  Future<int> add({
    required String name,
    required String type,
    required String labelEn,
    required String labelRu,
    required String iconName,
    required int colorValue,
  }) {
    return _db.insertCategory(
      CategoriesCompanion.insert(
        name: name,
        type: type,
        labelEn: Value(labelEn),
        labelRu: Value(labelRu),
        icon: Value(iconName),
        color: Value(colorValue.toString()),
        isDefault: const Value(false),
      ),
    );
  }

  Future<void> updateFields(
    int id, {
    required String type,
    required String labelEn,
    required String labelRu,
    required String iconName,
    required int colorValue,
  }) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        type: Value(type),
        labelEn: Value(labelEn),
        labelRu: Value(labelRu),
        icon: Value(iconName),
        color: Value(colorValue.toString()),
      ),
    );
  }

  Future<int> delete(int id) {
    return _db.deleteCategory(id);
  }
}
