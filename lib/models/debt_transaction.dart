class DebtTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'Terima' (pembayaran) atau 'Berikan' (pinjam/hutang baru)
  final String? notes; // Catatan untuk transaksi spesifik

  DebtTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type,
      'notes': notes,
    };
  }

  factory DebtTransaction.fromJson(Map<String, dynamic> json) {
    return DebtTransaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      notes: json['notes'] as String?,
    );
  }
}