import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String vacationId;
  final String payerId;
  final String payerName;
  final double amount; // in EGP
  final String description; // free text
  final List<String> splitWith; // user IDs to split with (defaults to all members)
  final DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.vacationId,
    required this.payerId,
    required this.payerName,
    required this.amount,
    required this.description,
    required this.splitWith,
    DateTime? date,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// How much each person in the split owes for this expense.
  double get perPersonShare => splitWith.isNotEmpty ? amount / splitWith.length : 0;

  factory Expense.fromFirestore(DocumentSnapshot doc, String vacationId) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      vacationId: vacationId,
      payerId: data['payerId'] ?? '',
      payerName: data['payerName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      splitWith: List<String>.from(data['splitWith'] ?? []),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'payerId': payerId,
      'payerName': payerName,
      'amount': amount,
      'description': description,
      'splitWith': splitWith,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Represents a settlement transaction: one person pays another.
class Settlement {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  Settlement({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });
}
