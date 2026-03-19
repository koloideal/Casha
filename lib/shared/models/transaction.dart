import 'package:flutter/foundation.dart';

enum TransactionType { income, expense }

@immutable
class Transaction {
  final String id;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String? note;

  const Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'type': type.name,
        'date': date.toIso8601String(),
        'note': note,
      };

  Transaction copyWith({
    String? id,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
  }) =>
      Transaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        date: date ?? this.date,
        note: note ?? this.note,
      );
}
