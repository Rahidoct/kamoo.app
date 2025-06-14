// lib/services/product_service.dart
import '../models/product.dart';
import 'data_manager.dart';

class ProductService {
  // Ini adalah metode untuk mendapatkan semua produk
  static Future<List<Product>> getProducts() async { // Nama metode: getProducts
    return await DataManager.loadProducts();
  }

  // Ini adalah metode untuk menyimpan daftar produk
  static Future<void> saveProducts(List<Product> products) async { // Nama metode: saveProducts
    await DataManager.saveProducts(products);
  }

  // Metode mencari produk berdasarkan barcode (sudah kita tambahkan sebelumnya)
  static Future<Product?> getProductByBarcode(String barcode) async {
    List<Product> products = await getProducts();
    try {
      return products.firstWhere((product) => product.id == barcode);
    } catch (e) {
      return null;
    }
  }

  // Metode CRUD lainnya
  static Future<void> addProduct(Product product) async {
    List<Product> currentProducts = await getProducts();
    currentProducts.add(product);
    await saveProducts(currentProducts);
  }

  static Future<void> updateProduct(Product product) async {
    List<Product> currentProducts = await getProducts();
    int index = currentProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      currentProducts[index] = product;
      await saveProducts(currentProducts);
    }
  }

  static Future<void> deleteProduct(String productId) async {
    List<Product> currentProducts = await getProducts();
    currentProducts.removeWhere((p) => p.id == productId);
    await saveProducts(currentProducts);
  }
}