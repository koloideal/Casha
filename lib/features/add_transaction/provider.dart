import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../shared/models/transaction.dart';

class AddTransactionState {
  final double? amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String note;
  final bool isSubmitting;
  final String? editingId;

  const AddTransactionState({
    this.amount,
    this.category = 'Food',
    this.type = TransactionType.expense,
    required this.date,
    this.note = '',
    this.isSubmitting = false,
    this.editingId,
  });

  AddTransactionState copyWith({
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
    bool? isSubmitting,
    String? editingId,
  }) =>
      AddTransactionState(
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        date: date ?? this.date,
        note: note ?? this.note,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        editingId: editingId ?? this.editingId,
      );

  bool get isEditing => editingId != null;
}

class AddTransactionNotifier extends StateNotifier<AddTransactionState> {
  AddTransactionNotifier()
      : super(AddTransactionState(date: DateTime.now()));

  void setAmount(double? v) => state = state.copyWith(amount: v);
  
  void setCategory(String v) => state = state.copyWith(category: v);
  
  void setType(TransactionType v) {
    // Reset category to first item of new type
    final newCategory = AppCategories.forType(v).first;
    state = state.copyWith(type: v, category: newCategory);
  }
  
  void setDate(DateTime v) => state = state.copyWith(date: v);
  
  void setNote(String v) => state = state.copyWith(note: v);
  
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  
  void initializeForEdit(Transaction transaction) {
    state = AddTransactionState(
      amount: transaction.amount,
      category: transaction.category,
      type: transaction.type,
      date: transaction.date,
      note: transaction.note ?? '',
      editingId: transaction.id,
    );
  }
  
  void reset() => state = AddTransactionState(date: DateTime.now());
}

final addTransactionProvider =
    StateNotifierProvider.autoDispose<AddTransactionNotifier, AddTransactionState>(
  (ref) => AddTransactionNotifier(),
);

// Reactive categories based on selected type
final availableCategoriesProvider = Provider.autoDispose<List<String>>((ref) {
  final type = ref.watch(addTransactionProvider.select((s) => s.type));
  return AppCategories.forType(type);
});
