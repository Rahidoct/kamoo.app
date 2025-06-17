class StoreInfo {
  final String? name;
  final String? address;
  final String? phoneNumber;
  final String? logoPath;
  final String? notes; // <-- TAMBAHKAN BARIS INI

  StoreInfo({
    this.name,
    this.address,
    this.phoneNumber,
    this.logoPath,
    this.notes, // <-- TAMBAHKAN INI KE KONSTRUKTOR
  });

  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      name: map['name'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      logoPath: map['storeLogoPath'], // Sesuaikan jika kunci di map berbeda
      notes: map['notes'], // <-- TAMBAHKAN INI UNTUK MEMBACA DARI MAP
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'storeLogoPath': logoPath, // Sesuaikan jika kunci di map berbeda
      'notes': notes, // <-- TAMBAHKAN INI UNTUK MENULIS KE MAP
    };
  }
}