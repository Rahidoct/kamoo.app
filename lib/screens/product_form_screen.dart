import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kamoo/models/product.dart';
import 'package:kamoo/screens/barcode_scanner_screen.dart';
import 'package:kamoo/services/product_service.dart'; // Import ProductService Anda

// Definisi konstanta untuk warna utama aplikasi
const Color kPrimaryColor = Color(0xFF084FEA);

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;

  const ProductFormScreen({super.key, this.product, this.initialBarcode});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  // Tidak perlu lagi membuat instance ProductService karena metodenya statis
  // final ProductService _productService = ProductService(); // HAPUS BARIS INI

  bool _isEditing = false;
  File? _selectedImage;
  bool _isSaving = false; // Mengubah nama dari _isLoading menjadi _isSaving

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _isEditing = true;
      _idController.text = widget.product!.id ?? '';
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      // Menggunakan .toStringAsFixed(0) untuk memastikan tidak ada desimal yang tidak perlu
      _buyPriceController.text = widget.product!.buyPrice.toStringAsFixed(0);
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toStringAsFixed(0);
      _unitController.text = widget.product!.unit;
      if (widget.product!.imagePath != null && widget.product!.imagePath!.isNotEmpty) {
        _selectedImage = File(widget.product!.imagePath!);
      }
    } else if (widget.initialBarcode != null) {
      _idController.text = widget.initialBarcode!;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _buyPriceController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeForId() async {
    try {
      final String? barcodeResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (!mounted) return; // Periksa mounted setelah await

      if (barcodeResult != null && barcodeResult.isNotEmpty) {
        // Cek apakah barcode sudah ada di database
        final existingProduct = await ProductService.getProductByBarcode(barcodeResult);
        if (!mounted) return; // Periksa mounted lagi

        if (existingProduct != null) {
          _showErrorNotification('Produk dengan barcode ini sudah ada.');
          // Opsional: Langsung navigasi ke edit produk jika barcode ditemukan
          // Navigator.pop(context);
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: existingProduct)));
          return;
        }

        setState(() {
          _idController.text = barcodeResult;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorNotification('Gagal memindai barcode: ${e.toString()}');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (!mounted) return; // Periksa mounted setelah await

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorNotification('Gagal memilih gambar: ${e.toString()}');
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryColor),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true); // Gunakan _isSaving

    try {
      final productId = _idController.text.trim();

      // Validasi unik ID/Barcode saat menambahkan produk baru
      if (!_isEditing) {
        final existingProduct = await ProductService.getProductByBarcode(productId);
        if (!mounted) return;
        if (existingProduct != null) {
          throw Exception('Produk dengan barcode/ID ini sudah ada.');
        }
      }

      final buyPrice = double.tryParse(_buyPriceController.text);
      final price = double.tryParse(_priceController.text);
      final stock = double.tryParse(_stockController.text);

      // Validasi parsing numerik
      if (buyPrice == null || price == null || stock == null) {
        throw Exception('Harga beli, harga jual, dan stok harus berupa angka yang valid.');
      }

      // Validasi harga jual > harga beli
      if (price <= buyPrice) {
        throw Exception('Harga jual harus lebih besar dari harga beli');
      }

      // Handle image
      String? imagePath;
      if (_selectedImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await _selectedImage!.copy('${appDir.path}/$fileName');
        imagePath = savedImage.path;
      } else if (_isEditing && widget.product?.imagePath != null) {
        // Jika sedang mengedit dan tidak ada gambar baru dipilih, pertahankan gambar lama
        imagePath = widget.product!.imagePath;
      }

      final product = Product(
        id: productId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        buyPrice: buyPrice,
        price: price,
        stock: stock,
        unit: _unitController.text.trim(),
        imagePath: imagePath,
      );

      // Gunakan metode statis dari ProductService
      if (_isEditing) {
        await ProductService.updateProduct(product); // Panggil metode update statis
      } else {
        await ProductService.addProduct(product); // Panggil metode add statis
      }

      if (!mounted) return; // Periksa mounted sebelum navigasi
      _showSuccessNotification(
        _isEditing ? 'Produk berhasil diperbarui' : 'Produk berhasil ditambahkan',
      );
      Navigator.pop(context, true); // Pop dengan hasil true untuk indikasi sukses
    } catch (e) {
      if (!mounted) return;
      // Periksa apakah pesan error berasal dari validasi kustom
      if (e is Exception) {
        _showErrorNotification(e.toString().replaceFirst('Exception: ', ''));
      } else {
        _showErrorNotification('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false); // Gunakan _isSaving
      }
    }
  }

  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan Foto Produk',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Barcode/ID Field
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Barcode/ID Produk',
                  prefixIcon: const Icon(Icons.barcode_reader),
                  suffixIcon: !_isEditing
                      ? IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scanBarcodeForId,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                readOnly: _isEditing, // ID tidak bisa diubah saat edit
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Barcode/ID tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Buy Price Field
              TextFormField(
                controller: _buyPriceController,
                decoration: InputDecoration(
                  labelText: 'Harga Beli',
                  prefixIcon: const Icon(Icons.label_important),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga beli tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sell Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Harga Jual',
                  prefixIcon: const Icon(Icons.label_important_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga jual tidak boleh kosong';
                  }
                  final buyPrice = double.tryParse(_buyPriceController.text);
                  final sellPrice = double.tryParse(value);

                  if (sellPrice == null) {
                    return 'Masukkan angka yang valid';
                  }
                  if (buyPrice != null && sellPrice <= buyPrice) {
                    return 'Harga jual harus lebih besar dari harga beli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock Field
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Stok',
                  prefixIcon: const Icon(Icons.inventory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit Field
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Satuan (pcs, kg, dll.)',
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Satuan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct, // Nonaktifkan tombol saat menyimpan
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white) // Tampilkan indikator loading di tombol
                      : Text(
                          _isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}