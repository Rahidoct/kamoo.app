import 'debt_transaction.dart'; // Import model transaksi yang baru

class Debt {
  final String id;
  final String customerName;
  double amount; // Diubah jadi non-final agar bisa diupdate saat pembayaran tanpa copyWith
  final DateTime date;
  final DateTime dueDate;
  String status; // Diubah jadi non-final
  final String notes;
  final List<DebtTransaction> transactions; // Tambahkan ini

  Debt({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.dueDate,
    this.status = 'Belum Lunas',
    this.notes = '',
    List<DebtTransaction>? transactions, // Parameter opsional
  }) : transactions = transactions ?? []; // Inisialisasi jika null

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'notes': notes,
      // Konversi daftar transaksi ke JSON
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    var transactionsFromJson = json['transactions'] as List?;
    List<DebtTransaction> transactionList = transactionsFromJson != null
        ? transactionsFromJson.map((i) => DebtTransaction.fromJson(i)).toList()
        : [];

    return Debt(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String,
      transactions: transactionList,
    );
  }

  // CopyWith sekarang akan mengcopy juga transaksi
  Debt copyWith({
    String? id,
    String? customerName,
    double? amount,
    DateTime? date,
    DateTime? dueDate,
    String? status,
    String? notes,
    List<DebtTransaction>? transactions,
  }) {
    return Debt(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      transactions: transactions ?? this.transactions,
    );
  }
}