// lib/models/transaction_item.dart
class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final String productUnit; // Tambahkan ini jika ada di model produk
  final double quantity;
  final double priceAtSale;
  final double subtotal;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.productUnit, // Pastikan ada
    required this.quantity,
    required this.priceAtSale,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      transactionId: json['transactionId'],
      productId: json['productId'],
      productName: json['productName'],
      productUnit: json['productUnit'] ?? '', // Handle null safety
      quantity: json['quantity'] as double,
      priceAtSale: json['priceAtSale'] as double,
      subtotal: json['subtotal'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'productName': productName,
      'productUnit': productUnit,
      'quantity': quantity,
      'priceAtSale': priceAtSale,
      'subtotal': subtotal,
    };
  }
}