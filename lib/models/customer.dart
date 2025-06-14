
class Customer {
  final String id; // ID unik untuk setiap pelanggan (jika diperlukan untuk fitur lain)
  final String name;
  final String phoneNumber;
  final String address;
  final List<String> transactionHistory; // Riwayat belanja

  Customer({
    required this.id, // ID tetap dibutuhkan untuk identifikasi pelanggan
    required this.name,
    required this.phoneNumber,
    this.address = '',
    List<String>? transactionHistory,
  }) : transactionHistory = transactionHistory ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'transactionHistory': transactionHistory,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      address: json['address'] ?? '',
      transactionHistory: List<String>.from(json['transactionHistory'] ?? []),
    );
  }
}