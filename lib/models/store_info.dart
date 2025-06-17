class StoreInfo {
  final String? nama;
  final String? address;
  final String? phoneNumber;
  final String? logoPath;
  final String? notes; // <-- TAMBAHKAN BARIS INI

  StoreInfo({
    this.nama,
    this.address,
    this.phoneNumber,
    this.logoPath,
    this.notes, // <-- TAMBAHKAN INI KE KONSTRUKTOR
  });

  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      nama: map['nama'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      logoPath: map['storeLogoPath'], // Sesuaikan jika kunci di map berbeda
      notes: map['notes'], // <-- TAMBAHKAN INI UNTUK MEMBACA DARI MAP
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'address': address,
      'phoneNumber': phoneNumber,
      'storeLogoPath': logoPath, // Sesuaikan jika kunci di map berbeda
      'notes': notes, // <-- TAMBAHKAN INI UNTUK MENULIS KE MAP
    };
  }
}