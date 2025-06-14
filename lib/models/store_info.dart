class StoreInfo {
  final String? name;
  final String? address;
  final String? phoneNumber;
  final String? logoPath; // Path ke logo di sistem file lokal

  StoreInfo({
    this.name,
    this.address,
    this.phoneNumber,
    this.logoPath,
  });

  // Contoh factory constructor jika Anda ingin mengonversi dari Map
  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      name: map['toko'] as String?, // Sesuaikan dengan key di LocalAuthService
      address: map['address'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      logoPath: map['storeLogoPath'] as String?,
    );
  }
}