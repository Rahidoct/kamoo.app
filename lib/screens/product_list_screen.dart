import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
import 'dart:io'; // Untuk File gambar

// Pastikan path import ini sesuai dengan struktur proyek Anda
import 'package:kamoo/models/product.dart';
import 'package:kamoo/services/product_service.dart'; // Sudah benar
import 'package:kamoo/screens/barcode_scanner_screen.dart'; 
import 'package:kamoo/screens/product_form_screen.dart'; 

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // TIDAK PERLU menginisialisasi ProductService sebagai instance
  // karena semua metodenya static. Kita akan langsung memanggil ProductService.namaMetode()

  late Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Menggunakan addListener untuk memuat ulang produk saat teks pencarian berubah
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- Fungsi untuk Memuat Produk ---
  void _loadProducts({String? searchQuery}) {
    setState(() {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Jika ada query pencarian, kita filter dari semua produk
        // UBAH: _productService.getAllProducts() menjadi ProductService.getProducts()
        _productsFuture = ProductService.getProducts().then((allProducts) {
          return allProducts.where((product) {
            final lowerCaseQuery = searchQuery.toLowerCase();
            return product.name.toLowerCase().contains(lowerCaseQuery) ||
                   (product.id != null && product.id!.toLowerCase().contains(lowerCaseQuery));
          }).toList();
        });
      } else {
        // Jika tidak ada query, muat semua produk
        // UBAH: _productService.getAllProducts() menjadi ProductService.getProducts()
        _productsFuture = ProductService.getProducts();
      }
    });
  }

  void _onSearchChanged() {
    _loadProducts(searchQuery: _searchController.text);
  }

  // --- Fungsi untuk Scan Barcode dan Pencarian ---
  Future<void> _scanBarcodeForSearch() async {
    // Memanggil screen BarcodeScannerScreen
    final String? barcodeResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcodeResult != null && barcodeResult.isNotEmpty) {
      // Set hasil scan ke controller pencarian dan muat ulang produk
      _searchController.text = barcodeResult;
      _loadProducts(searchQuery: barcodeResult);
    }
  }

  // --- Fungsi Konfirmasi Hapus Produk ---
  Future<void> _confirmDelete(String productId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 10,
        title: const Center(
          child: Text(
            'Hapus Barang ini.?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Apakah Anda yakin ingin menghapus barang ini?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.grey[300],
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.red[600],
              elevation: 3,
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // UBAH: _productService.deleteProduct() menjadi ProductService.deleteProduct()
        await ProductService.deleteProduct(productId); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Barang berhasil dihapus!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              margin: const EdgeInsets.all(20),
            ),
          );
          _loadProducts(searchQuery: _searchController.text); // Muat ulang setelah hapus
        }
      } catch (e) {
        // shared_preferences tidak memiliki konsep foreign key constraint seperti database relasional.
        // Jadi pesan error ini kemungkinan tidak akan muncul persis sama.
        // Anda mungkin perlu menambahkan logic untuk cek apakah produk masih "digunakan"
        // di keranjang atau riwayat transaksi jika Anda menyimpan data tersebut di shared_preferences juga.
        String errorMessage = 'Gagal menghapus barang.';
        if (e.toString().contains('FOREIGN KEY constraint failed')) { // Ini untuk SQLite/Database
          errorMessage = 'Produk tidak bisa dihapus karena digunakan untuk riwayat transaksi.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(errorMessage),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE4E8F0),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Cari produkmu',
                        hintText: 'Ketik nama atau scan kode...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scanBarcodeForSearch,
                          tooltip: 'Pindai Barcode',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF084FEA),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      // onChanged: (value) => _loadProducts(searchQuery: value), // Listener sudah di initState
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Product List
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF084FEA)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memuat data...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat data barang: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Silakan coba lagi nanti',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadProducts(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada barang atau produk nih...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yuk tambahkan barang atau produkmu...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final products = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80), // Tambahkan padding agar FAB tidak menutupi item terakhir
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                // Aksi ketika item di-tap (misalnya, edit)
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductFormScreen(product: product),
                                  ),
                                );
                                if (result == true) {
                                  _loadProducts(searchQuery: _searchController.text);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Product Image
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                      ),
                                      child: product.imagePath != null && product.imagePath!.isNotEmpty
                                          ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(product.imagePath!), // Menggunakan File dari dart:io
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          size: 30,
                                                          color: Colors.grey[400],
                                                        ),
                                                      ),
                                                ),
                                              )
                                          : Center(
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  size: 40,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Product Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ID: ${product.id ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                // Gunakan NumberFormat untuk format mata uang
                                                'Rp. ${NumberFormat('#,###', 'id_ID').format(product.price)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF084FEA),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                'Stok: ${product.stock.toStringAsFixed(0)} ${product.unit}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: product.stock > 0
                                                      ? Colors.green[600]
                                                      : Colors.red[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Buttons
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF084FEA), 
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.white, 
                                              size: 20,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProductFormScreen(product: product),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadProducts(searchQuery: _searchController.text);
                                            }
                                          },
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red, // Latar belakang merah
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white, // UBAH INI: Warna ikon menjadi putih
                                              size: 20,
                                            ),
                                          ),
                                          // UBAH: _productService.deleteProduct() menjadi ProductService.deleteProduct()
                                          onPressed: () => _confirmDelete(product.id!),
                                          tooltip: 'Hapus',
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      // FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
          if (result == true) {
            _loadProducts(searchQuery: _searchController.text);
          }
        },
        backgroundColor: const Color(0xFF084FEA),
        foregroundColor: Colors.white,
        tooltip: 'Tambah Barang Baru',
        child: const Icon(Icons.add_box),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}