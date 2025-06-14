// lib/models/transaction.dart
import 'package:kamoo/models/transaction_item.dart'; // PENTING: Import dari file terpisah

class Transaction {
  final String id;
  final String? customerId;
  final DateTime transactionDate;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final List<TransactionItem> items; // Ini harus menggunakan TransactionItem dari import di atas

  Transaction({
    required this.id,
    this.customerId,
    required this.transactionDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.items,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<TransactionItem> items = itemsList
        .map((i) => TransactionItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return Transaction(
      id: json['id'],
      customerId: json['customerId'],
      transactionDate: DateTime.parse(json['transactionDate']),
      totalAmount: json['totalAmount'] as double,
      paidAmount: json['paidAmount'] as double,
      changeAmount: json['changeAmount'] as double,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'transactionDate': transactionDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'changeAmount': changeAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}