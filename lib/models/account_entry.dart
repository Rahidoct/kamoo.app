// lib/models/account_entry.dart
class AccountEntry {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final AccountEntryType type;

  AccountEntry({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  // Manual toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(), // Simpan sebagai String ISO 8601
      'type': type.toString().split('.').last, // Simpan enum sebagai string
    };
  }

  // Manual fromJson
  factory AccountEntry.fromJson(Map<String, dynamic> json) {
    return AccountEntry(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
      date: DateTime.parse(json['date']), // Parse kembali dari String
      type: AccountEntryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
    );
  }
}

enum AccountEntryType {
  income,
  expense,
}