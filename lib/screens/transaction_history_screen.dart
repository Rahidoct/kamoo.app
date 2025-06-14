import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../auth/local_auth_service.dart'; 
import '../models/transaction.dart' as app_transaction; 
import '../models/transaction_item.dart' as transaction_item; 
import '../models/customer.dart';
import '../models/store_info.dart';
import '../services/transaction_service.dart';
import '../services/customer_service.dart';
import 'receipt_screen.dart'; 

// Definisi konstanta untuk warna utama aplikasi
const Color kPrimaryColor = Color(0xFF084FEA);

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _transactionsWithCustomerFuture;
  StoreInfo? _storeInfo; // Variable untuk menyimpan data toko

  // Formatter untuk mata uang dan tanggal
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadStoreInfo(); // Panggil untuk memuat data toko saat initState
    _refreshTransactionList();
  }

  Future<void> _loadStoreInfo() async {
    final Map<String, dynamic>? loggedInUser = await LocalAuthService.getLoggedInUser();
    if (loggedInUser != null) {
      setState(() {
        _storeInfo = StoreInfo.fromMap(loggedInUser);
      });
    }
  }

  Future<void> _refreshTransactionList() async {
    setState(() {
      _transactionsWithCustomerFuture = _getTransactionsWithCustomer();
    });
  }

  // Helper method untuk mendapatkan transaksi beserta nama pelanggan
  Future<List<Map<String, dynamic>>> _getTransactionsWithCustomer() async {
    List<app_transaction.Transaction> transactions = await TransactionService.getTransactions();
    List<Map<String, dynamic>> result = [];

    for (var transaction in transactions) {
      String customerName = 'Umum'; // Default untuk pelanggan umum
      Customer? customer;
      if (transaction.customerId != null && transaction.customerId!.isNotEmpty) {
        customer = await CustomerService.getCustomerById(transaction.customerId!);
        customerName = customer?.name ?? 'Umum'; // Jika ID ada tapi nama tidak ditemukan
      }
      result.add({
        'transaction': transaction,
        'customerName': customerName,
        'customer': customer, // Teruskan objek customer lengkap untuk ReceiptScreen
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator( // Tambahkan RefreshIndicator
        onRefresh: _refreshTransactionList,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _transactionsWithCustomerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada riwayat transaksi.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            } else {
              // Sort transaksi berdasarkan tanggal terbaru
              final sortedTransactions = snapshot.data!..sort((a, b) {
                final transA = a['transaction'] as app_transaction.Transaction;
                final transB = b['transaction'] as app_transaction.Transaction;
                return transB.transactionDate.compareTo(transA.transactionDate); // Terbaru di atas
              });

              return ListView.builder(
                itemCount: sortedTransactions.length,
                itemBuilder: (context, index) {
                  final transactionData = sortedTransactions[index];
                  final app_transaction.Transaction transaction = transactionData['transaction'];
                  final String customerName = transactionData['customerName'];
                  final Customer? customer = transactionData['customer'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell( // Menggunakan InkWell untuk efek tap yang lebih baik
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (!mounted) return; // Pastikan widget masih ada

                        // Penting: Pastikan _storeInfo sudah ada sebelum navigasi
                        // Jika _storeInfo masih null (misalnya, loading belum selesai),
                        // Anda bisa menampilkan pesan atau menunggu.
                        // Untuk contoh ini, kita asumsikan _storeInfo akan tersedia.
                        // Jika tidak, ReceiptScreen akan menerima null untuk storeInfo.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceiptScreen(
                              transaction: transaction,
                              items: transaction.items.cast<transaction_item.TransactionItem>(),
                              customer: customer,
                              paidAmount: transaction.paidAmount,
                              changeAmount: transaction.changeAmount,
                              storeInfo: _storeInfo, // <-- KIRIM DATA TOKO DI SINI
                            ),
                          ),
                        ).then((_) {
                          // Refresh daftar setelah kembali dari ReceiptScreen (jika ada perubahan/delete)
                          _refreshTransactionList();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ID Transaksi: ${transaction.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kPrimaryColor,
                                  ),
                                ),
                                Text(
                                  _currencyFormatter.format(transaction.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tanggal: ${_dateFormatter.format(transaction.transactionDate)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pelanggan: $customerName',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jumlah Item: ${transaction.items.length}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
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
    );
  }
}