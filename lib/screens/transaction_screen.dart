import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/local_auth_service.dart';
 
// Import Models
import '../models/store_info.dart';
import '../models/product.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';
import '../models/customer.dart';

// Import Services
import '../services/product_service.dart';
import '../services/transaction_service.dart';
import '../services/customer_service.dart';

// Import Screens
import 'barcode_scanner_screen.dart';
import 'product_selection_screen.dart';
import 'post_transaction_screen.dart';
//import 'receipt_screen.dart';

class CartItem {
  Product product;
  double quantity;

  CartItem({required this.product, this.quantity = 1.0});

  double get subtotal => product.price * quantity;
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final List<CartItem> _cartItems = [];
  double _totalAmount = 0.0;
  Customer? _selectedCustomer; // Bisa null, tapi akan diset default
  late Future<List<Customer>> _customersFuture;
  final TextEditingController _paidAmountController = TextEditingController();
  double _paidAmount = 0.0;
  double _changeAmount = 0.0;

  final Uuid _uuid = Uuid();

  // Definisikan Pelanggan Umum secara statis atau sebagai final field
  // agar objeknya selalu sama dan dapat dibandingkan
  static final Customer _generalCustomer = Customer(id: 'umum', name: 'Pelanggan Umum', phoneNumber: '');


  @override
  void initState() {
    super.initState();
    // Mengambil semua pelanggan, lalu menambahkan 'Pelanggan Umum' di awal
    _customersFuture = _loadCustomersWithGeneral();
    _paidAmountController.addListener(_onPaidAmountChanged);
  }

  // Fungsi baru untuk memuat pelanggan dan menambahkan "Pelanggan Umum"
  Future<List<Customer>> _loadCustomersWithGeneral() async {
    List<Customer> fetchedCustomers = await CustomerService.getCustomers();
    // Pastikan _generalCustomer tidak ada di fetchedCustomers
    // sebelum ditambahkan untuk menghindari duplikasi ID jika customer service juga mengembalikan 'umum'
    fetchedCustomers.removeWhere((c) => c.id == _generalCustomer.id);

    List<Customer> allCustomers = [_generalCustomer, ...fetchedCustomers];

    // Set _selectedCustomer ke _generalCustomer setelah daftar dimuat
    // agar value dropdown selalu cocok dengan salah satu item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedCustomer == null) {
        setState(() {
          _selectedCustomer = _generalCustomer;
        });
      }
    });

    return allCustomers;
  }

  @override
  void dispose() {
    _paidAmountController.removeListener(_onPaidAmountChanged);
    _paidAmountController.dispose();
    super.dispose();
  }

  void _onPaidAmountChanged() {
    setState(() {
      final String text = _paidAmountController.text;
      final cleanedText = text.replaceAll(RegExp(r'[^\d.]'), '');
      final parts = cleanedText.split('.');
      if (parts.length > 2) {
        _paidAmountController.text = '${parts[0]}.${parts.sublist(1).join()}';
        _paidAmountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _paidAmountController.text.length),
        );
        return;
      }
      _paidAmount = double.tryParse(cleanedText) ?? 0.0;
      _calculateChange();
    });
  }

  void _updateTotal() {
    setState(() {
      _totalAmount = _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
      _calculateChange();
    });
  }

  void _calculateChange() {
    setState(() {
      _changeAmount = _paidAmount - _totalAmount;
    });
  }

  void _addProductToCart(Product product) {
    int existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (_cartItems[existingIndex].quantity + 1 > product.stock) {
        _showSnackBar('Stok ${product.name} hanya ${product.stock.toStringAsFixed(0)} ${product.unit}.');
        return;
      }
      setState(() {
        _cartItems[existingIndex].quantity++;
      });
    } else {
      if (1 > product.stock) {
        _showSnackBar('Stok ${product.name} hanya ${product.stock.toStringAsFixed(0)} ${product.unit}.');
        return;
      }
      setState(() {
        _cartItems.add(CartItem(product: product));
      });
    }
    _updateTotal();
  }

  void _changeQuantity(CartItem item, double delta) {
    final newQuantity = item.quantity + delta;
    if (newQuantity > item.product.stock) {
      _showSnackBar('Stok ${item.product.name} hanya ${item.product.stock.toStringAsFixed(0)} ${item.product.unit}.');
      return;
    }

    setState(() {
      item.quantity = newQuantity;
      if (item.quantity <= 0) {
        _cartItems.remove(item);
      }
      _updateTotal();
    });
  }

  Future<void> _scanBarcode() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ),
    );

    final String? barcodeResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    Navigator.of(context).pop();

    if (barcodeResult != null && barcodeResult.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mencari produk...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      try {
        Product? product = await ProductService.getProductByBarcode(barcodeResult);

        Navigator.of(context).pop();

        if (product != null) {
          _addProductToCart(product);
          _showSuccessMessage('Produk ${product.name} berhasil ditambahkan ke keranjang.');
        } else {
          _showErrorMessage('Yah.. barcode produk tidak ditemukan. :(');
        }
      } catch (e) {
        Navigator.of(context).pop();
        _showErrorMessage('Terjadi kesalahan: ${e.toString()}');
      }
    } else {
      _showInfoMessage('Pemindaian atau scan barcode dibatalkan.');
    }
  }

  Future<void> _searchAndSelectProduct() async {
    final Product? selectedProduct = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    if (selectedProduct != null) {
      _addProductToCart(selectedProduct);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isInfo = false}) {
    if (!mounted) return;

    IconData icon;
    Color color;

    if (isError) {
      icon = Icons.error_outline;
      color = Colors.redAccent;
    } else if (isInfo) {
      icon = Icons.info_outline;
      color = Colors.blueGrey;
    } else {
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    _showSnackBar(message, isError: false);
  }

  void _showErrorMessage(String message) {
    _showSnackBar(message, isError: true);
  }

  void _showInfoMessage(String message) {
    _showSnackBar(message, isInfo: true);
  }

  Future<String> _generateTransactionId() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final String todayDate = DateFormat('ddMMyyyy').format(now);

    String lastTransactionDate = prefs.getString('lastTransactionDate') ?? '';
    int dailySequence = prefs.getInt('dailyTransactionSequence') ?? 0;

    if (lastTransactionDate != todayDate) {
      dailySequence = 1;
      await prefs.setString('lastTransactionDate', todayDate);
    } else {
      dailySequence++;
    }

    await prefs.setInt('dailyTransactionSequence', dailySequence);

    return 'INV$todayDate$dailySequence';
  }

  Future<void> _saveTransaction() async {
    if (_cartItems.isEmpty) {
      _showErrorMessage('Keranjang belanja kosong!');
      return;
    }

    if (_paidAmount < _totalAmount) {
      _showErrorMessage('Uang yang dibayarkan kurang! Rp. ${NumberFormat('#,###', 'id_ID').format(_totalAmount - _paidAmount)} lagi.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Konfirmasi Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Belanja:'),
                    Text('Rp ${NumberFormat('#,###', 'id_ID').format(_totalAmount)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Uang Dibayar:'),
                    Text('Rp ${NumberFormat('#,###', 'id_ID').format(_paidAmount)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kembalian:',
                      style: TextStyle(color: Colors.green),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(_changeAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _changeAmount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Batal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Bayar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final String transactionId = await _generateTransactionId();

    final List<TransactionItem> transactionItems = _cartItems.map((cartItem) {
      return TransactionItem(
        id: _uuid.v4(),
        transactionId: transactionId,
        productId: cartItem.product.id!,
        productName: cartItem.product.name,
        productUnit: cartItem.product.unit,
        quantity: cartItem.quantity,
        priceAtSale: cartItem.product.price,
        subtotal: cartItem.subtotal,
      );
    }).toList();

    final app_transaction.Transaction newTransaction = app_transaction.Transaction(
      id: transactionId,
      customerId: _selectedCustomer?.id,
      transactionDate: DateTime.now(),
      totalAmount: _totalAmount,
      paidAmount: _paidAmount,
      changeAmount: _changeAmount,
      items: transactionItems,
    );

    try {
      await TransactionService.addTransaction(newTransaction);

      List<Product> currentProducts = await ProductService.getProducts();
      for (var cartItem in _cartItems) {
        int productIndex = currentProducts.indexWhere((p) => p.id == cartItem.product.id);
        if (productIndex != -1) {
          currentProducts[productIndex] = currentProducts[productIndex].copyWith(
            stock: currentProducts[productIndex].stock - cartItem.quantity,
          );
        }
      }
      await ProductService.saveProducts(currentProducts);

      _showSuccessMessage('Transaksi berhasil disimpan!');

      final Map<String, dynamic>? loggedInUser = await LocalAuthService.getLoggedInUser();
      final StoreInfo storeInfo = StoreInfo.fromMap(loggedInUser ?? {});

      final paid = _paidAmount;
      final change = _changeAmount;
      final selectedCustomerForReceipt = _selectedCustomer;

      // --- PERUBAHAN NAVIGASI DI SINI ---
      // Navigasi ke PostTransactionScreen, dan hapus TransactionScreen dari stack
      Navigator.pushReplacement( // Menggunakan pushReplacement
        context,
        MaterialPageRoute(
          builder: (context) => PostTransactionScreen(
            transaction: newTransaction,
            items: transactionItems,
            customer: selectedCustomerForReceipt,
            paidAmount: paid,
            changeAmount: change,
            storeInfo: storeInfo,
          ),
        ),
      );

      // Reset state setelah transaksi berhasil dan navigasi
      setState(() {
        _cartItems.clear();
        _totalAmount = 0.0;
        _selectedCustomer = _generalCustomer; // Reset ke 'Pelanggan Umum'
        _paidAmountController.clear();
        _paidAmount = 0.0;
        _changeAmount = 0.0;
      });
    } catch (e) {
      _showErrorMessage('Gagal menyimpan transaksi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Customer selection and product buttons
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    FutureBuilder<List<Customer>>(
                      future: _customersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Tidak ada pelanggan');
                        } else {
                          // Gunakan daftar pelanggan yang sudah termasuk "Pelanggan Umum"
                          List<Customer> customers = snapshot.data!;
                          return DropdownButtonFormField<Customer?>(
                            decoration: InputDecoration(
                              labelText: 'Pilih Pelanggan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            // Penting: pastikan _selectedCustomer adalah salah satu dari objek di 'items'
                            value: _selectedCustomer,
                            items: customers.map((customer) => DropdownMenuItem(
                              value: customer,
                              child: Text(customer.name),
                            )).toList(),
                            onChanged: (customer) {
                              setState(() {
                                _selectedCustomer = customer;
                              });
                            },
                            isExpanded: true,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Pindai Barcode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              minimumSize: const Size.fromHeight(40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _searchAndSelectProduct,
                            icon: const Icon(Icons.search),
                            label: const Text('Cari Produk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              minimumSize: const Size.fromHeight(40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      
          // Cart items
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Keranjang Belanja Kosong',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pindai barcode atau cari produk',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag, size: 30, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp. ${NumberFormat('#,###', 'id_ID').format(item.product.price)}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stok: ${item.product.stock.toStringAsFixed(0)} ${item.product.unit}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _changeQuantity(item, -1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(Icons.remove, size: 18, color: Colors.red),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.quantity.toStringAsFixed(0),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _changeQuantity(item, 1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(Icons.add, size: 18, color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Rp. ${NumberFormat('#,###', 'id_ID').format(item.subtotal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
      
          // Checkout Summary & Button
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 3,
                top: 2,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.playlist_add_circle_outlined, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('Total:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('Rp. ${NumberFormat('#,###', 'id_ID').format(_totalAmount)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Uang Dibayar',
                      prefixText: 'Rp. ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.change_circle_outlined, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('Kembalian:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        'Rp. ${NumberFormat('#,###', 'id_ID').format(_changeAmount)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _changeAmount >= 0 ? Colors.blue : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF084FEA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'PROSES TRANSAKSI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}