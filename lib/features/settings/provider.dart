import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/provider.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, double?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BudgetNotifier(storage.loadBudget(), storage);
});

class BudgetNotifier extends StateNotifier<double?> {
  final dynamic _storage;

  BudgetNotifier(super.initialBudget, this._storage);

  Future<void> setBudget(double? budget) async {
    await _storage.saveBudget(budget);
    state = budget;
  }
}
