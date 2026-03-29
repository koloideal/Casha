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
  final String overrideCurrency;
  final String overrideCurrencyCode;
  final int? selectedAccountId;
  final int? toAccountId;

  const AddTransactionState({
    this.amount,
    this.category = 'Salary',
    this.type = TransactionType.income,
    required this.date,
    this.note = '',
    this.isSubmitting = false,
    this.editingId,
    this.overrideCurrency = '\$',
    this.overrideCurrencyCode = 'USD',
    this.selectedAccountId,
    this.toAccountId,
  });

  factory AddTransactionState.fromTransaction(Transaction tx) {
    // Override type to transfer when category is 'Transfer'
    final resolvedType = (tx.category == 'Transfer')
        ? TransactionType.transfer
        : tx.type;

    return AddTransactionState(
      amount: tx.amount,
      category: tx.category,
      type: resolvedType,
      date: tx.date,
      note: tx.note ?? '',
      editingId: tx.id,
      overrideCurrency: tx.currency,
      overrideCurrencyCode: tx.currencyCode,
      selectedAccountId: tx.accountId,
    );
  }

  factory AddTransactionState.empty() {
    return AddTransactionState(date: DateTime.now(), selectedAccountId: null);
  }

  AddTransactionState copyWith({
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
    bool? isSubmitting,
    String? editingId,
    String? overrideCurrency,
    String? overrideCurrencyCode,
    int? selectedAccountId,
    int? toAccountId,
  }) => AddTransactionState(
    amount: amount ?? this.amount,
    category: category ?? this.category,
    type: type ?? this.type,
    date: date ?? this.date,
    note: note ?? this.note,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    editingId: editingId ?? this.editingId,
    overrideCurrency: overrideCurrency ?? this.overrideCurrency,
    overrideCurrencyCode: overrideCurrencyCode ?? this.overrideCurrencyCode,
    selectedAccountId: selectedAccountId ?? this.selectedAccountId,
    toAccountId: toAccountId ?? this.toAccountId,
  );

  bool get isEditing => editingId != null;
}

class AddTransactionNotifier extends StateNotifier<AddTransactionState> {
  AddTransactionNotifier(Transaction? initial)
    : super(
        initial != null
            ? AddTransactionState.fromTransaction(initial)
            : AddTransactionState.empty(),
      );

  void setAmount(double? v) => state = state.copyWith(amount: v);

  void setCategory(String v) => state = state.copyWith(category: v);

  void setType(TransactionType v) {
    if (v == TransactionType.transfer) {
      state = state.copyWith(type: v, category: 'Transfer', toAccountId: null);
    } else {
      final newCategory = AppCategories.forType(v).first;
      state = state.copyWith(type: v, category: newCategory, toAccountId: null);
    }
  }

  void setDate(DateTime v) => state = state.copyWith(date: v);

  void setNote(String v) => state = state.copyWith(note: v);

  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);

  void setCurrency(String symbol, String code) {
    state = state.copyWith(
      overrideCurrency: symbol,
      overrideCurrencyCode: code,
    );
  }

  void setAccountId(int id) => state = state.copyWith(selectedAccountId: id);

  void setToAccountId(int? id) => state = state.copyWith(toAccountId: id);

  bool get isTransfer => state.type == TransactionType.transfer;

  void reset() => state = AddTransactionState.empty();
}

final addTransactionProvider = StateNotifierProvider.autoDispose
    .family<AddTransactionNotifier, AddTransactionState, Transaction?>(
      (ref, initial) => AddTransactionNotifier(initial),
    );

final availableCategoriesProvider = Provider.autoDispose
    .family<List<String>, Transaction?>((ref, initial) {
      final type = ref.watch(
        addTransactionProvider(initial).select((s) => s.type),
      );
      return AppCategories.forType(type);
    });
