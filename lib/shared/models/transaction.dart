import 'package:flutter/foundation.dart';

enum TransactionType { income, expense, transfer }

enum RecurrenceType { none, daily, weekly, monthly }

@immutable
class Transaction {
  final String id;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final RecurrenceType recurrence;
  final DateTime? lastOccurrence;
  final String currency;
  final String currencyCode;
  final int accountId;

  const Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note,
    this.recurrence = RecurrenceType.none,
    this.lastOccurrence,
    this.currency = '\$',
    this.currencyCode = 'USD',
    required this.accountId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    type: TransactionType.values.firstWhere((e) => e.name == json['type']),
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String?,
    recurrence: json['recurrence'] != null
        ? RecurrenceType.values.firstWhere(
            (e) => e.name == json['recurrence'],
            orElse: () => RecurrenceType.none,
          )
        : RecurrenceType.none,
    lastOccurrence: json['lastOccurrence'] != null
        ? DateTime.parse(json['lastOccurrence'] as String)
        : null,
    currency: json['currency'] as String? ?? '\$',
    currencyCode: json['currencyCode'] as String? ?? 'USD',
    accountId: json['accountId'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'type': type.name,
    'date': date.toIso8601String(),
    'note': note,
    'recurrence': recurrence.name,
    'lastOccurrence': lastOccurrence?.toIso8601String(),
    'currency': currency,
    'currencyCode': currencyCode,
    'accountId': accountId,
  };

  Transaction copyWith({
    String? id,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
    RecurrenceType? recurrence,
    DateTime? lastOccurrence,
    String? currency,
    String? currencyCode,
    int? accountId,
  }) => Transaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    type: type ?? this.type,
    date: date ?? this.date,
    note: note ?? this.note,
    recurrence: recurrence ?? this.recurrence,
    lastOccurrence: lastOccurrence ?? this.lastOccurrence,
    currency: currency ?? this.currency,
    currencyCode: currencyCode ?? this.currencyCode,
    accountId: accountId ?? this.accountId,
  );
}
