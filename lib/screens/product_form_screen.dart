import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kamoo/models/product.dart';
import 'package:kamoo/screens/barcode_scanner_screen.dart';
import 'package:kamoo/services/product_service.dart';

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

  bool _isEditing = false;
  File? _selectedImage;
  bool _isSaving = false;
  late FToast fToast; // Untuk notifikasi menarik

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context); // Inisialisasi FToast

    if (widget.product != null) {
      _isEditing = true;
      _idController.text = widget.product!.id ?? '';
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _buyPriceController.text = widget.product!.buyPrice.toStringAsFixed(0);
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toStringAsFixed(0);
      _unitController.text = widget.product!.unit;
      if (widget.product!.imagePath != null && widget.product!.imagePath!.isNotEmpty) {
        _selectedImage = File(widget.product!.imagePath!);
      }
    } else if (widget.initialBarcode != null) {
      _idController.text = widget.initialBarcode!;
    } else {
      _proposeAutoProductId();
    }
  }

  Future<void> _proposeAutoProductId() async {
    final prefs = await SharedPreferences.getInstance();
    final int lastSavedProdSequence = prefs.getInt('lastProdIdSequence') ?? 0;
    final String proposedId = 'Prod#${(lastSavedProdSequence + 1).toString().padLeft(4, '0')}';
    
    if (_idController.text.isEmpty) {
      setState(() {
        _idController.text = proposedId;
      });
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

      if (!mounted) return;

      if (barcodeResult != null && barcodeResult.isNotEmpty) {
        final existingProduct = await ProductService.getProductByBarcode(barcodeResult);
        if (!mounted) return;

        if (existingProduct != null) {
          _showErrorNotification('Produk dengan barcode ini sudah ada.');
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

      if (!mounted) return;

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
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
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

    setState(() => _isSaving = true);

    try {
      final productId = _idController.text.trim();

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

      if (buyPrice == null || price == null || stock == null) {
        throw Exception('Harga beli, harga jual, dan stok harus berupa angka yang valid.');
      }

      if (price <= buyPrice) {
        throw Exception('Harga jual harus lebih besar dari harga beli');
      }

      String? imagePath;
      if (_selectedImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await _selectedImage!.copy('${appDir.path}/$fileName');
        imagePath = savedImage.path;
      } else if (_isEditing && widget.product?.imagePath != null) {
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

      if (_isEditing) {
        await ProductService.updateProduct(product);
      } else {
        await ProductService.addProduct(product);

        final prefs = await SharedPreferences.getInstance();
        final int lastSavedProdSequence = prefs.getInt('lastProdIdSequence') ?? 0;

        if (productId.startsWith('Prod#') && productId.length > 5) {
          final String numPart = productId.substring(5);
          final int? currentProdSequence = int.tryParse(numPart);

          if (currentProdSequence != null && currentProdSequence > lastSavedProdSequence) {
            await prefs.setInt('lastProdIdSequence', currentProdSequence);
          }
        }
      }

      if (!mounted) return;
      _showSuccessNotification(
        _isEditing ? 'Yay! Produk berhasil diperbarui' : 'Yay! Produk berhasil ditambahkan',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (e is Exception) {
        _showErrorNotification(' ${e.toString().replaceFirst('Exception: ', '')}');
      } else {
        _showErrorNotification('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ===== NOTIFIKASI MENARIK =====
  void _showSuccessNotification(String message) {
    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.green.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(seconds: 3),
    );
  }

  void _showErrorNotification(String message) {
    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message.length > 50 ? '${message.substring(0, 50)}...' : message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
                readOnly: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Barcode/ID produk tidak boleh kosong';
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
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
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