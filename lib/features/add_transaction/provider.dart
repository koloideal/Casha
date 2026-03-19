import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/transaction.dart';

class AddTransactionState {
  final double? amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String note;
  final bool isSubmitting;

  const AddTransactionState({
    this.amount,
    this.category = 'Food',
    this.type = TransactionType.expense,
    required this.date,
    this.note = '',
    this.isSubmitting = false,
  });

  AddTransactionState copyWith({
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
    bool? isSubmitting,
  }) =>
      AddTransactionState(
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        date: date ?? this.date,
        note: note ?? this.note,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class AddTransactionNotifier extends StateNotifier<AddTransactionState> {
  AddTransactionNotifier()
      : super(AddTransactionState(date: DateTime.now()));

  void setAmount(double? v) => state = state.copyWith(amount: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setType(TransactionType v) => state = state.copyWith(type: v);
  void setDate(DateTime v) => state = state.copyWith(date: v);
  void setNote(String v) => state = state.copyWith(note: v);
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void reset() => state = AddTransactionState(date: DateTime.now());
}

final addTransactionProvider =
    StateNotifierProvider.autoDispose<AddTransactionNotifier, AddTransactionState>(
  (ref) => AddTransactionNotifier(),
);
