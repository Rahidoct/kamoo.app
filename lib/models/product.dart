class Product {
  String? id;
  String name;
  String? description;
  double buyPrice;
  double price;
  double stock;
  String unit;
  String? imagePath;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.buyPrice,
    required this.price,
    required this.stock,
    required this.unit,
    this.imagePath,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'buyPrice': buyPrice,
      'price': price,
      'stock': stock,
      'unit': unit,
      'imagePath': imagePath,
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? 'Unknown Product',
        description: json['description']?.toString(),
        buyPrice: _parseDouble(json['buyPrice']),
        price: _parseDouble(json['price']),
        stock: _parseDouble(json['stock']),
        unit: json['unit']?.toString() ?? 'pcs',
        imagePath: json['imagePath']?.toString(),
      );
    } catch (e) {
      throw FormatException('Failed to parse Product: $e');
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? buyPrice,
    double? price,
    double? stock,
    String? unit,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      buyPrice: buyPrice ?? this.buyPrice,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'Product($id, $name, $price)';
  }
}