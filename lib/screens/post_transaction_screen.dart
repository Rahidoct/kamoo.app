// lib/screens/post_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:kamoo/models/transaction.dart' as app_transaction;
import 'package:kamoo/models/transaction_item.dart';
import 'package:kamoo/models/customer.dart';
import 'package:kamoo/models/store_info.dart';
// import 'package:kamoo/screens/transaction_screen.dart'; // Tidak perlu diimpor langsung jika akan kembali ke HomeScreen

import 'home_screen.dart'; // Penting: Kembali ke HomeScreen

class PostTransactionScreen extends StatelessWidget {
  final app_transaction.Transaction transaction;
  final List<TransactionItem> items;
  final Customer? customer;
  final double paidAmount;
  final double changeAmount;
  final StoreInfo? storeInfo;

  PostTransactionScreen({
    super.key,
    required this.transaction,
    required this.items,
    this.customer,
    required this.paidAmount,
    required this.changeAmount,
    this.storeInfo,
  });

  final NumberFormat _currencyFormatter =
      NumberFormat('#,###', 'id_ID');
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy HH:mm', 'id_ID');

  Widget _buildReceiptInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isChange = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isChange ? 18 : 16,
              color: isChange ? (amount >= 0 ? Colors.green : Colors.black) : Colors.black,
            ),
          ),
          Text(
            'Rp ${_currencyFormatter.format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isChange ? 18 : 16,
              color: isChange ? (amount >= 0 ? Colors.green : Colors.red) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi Selesai'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'ID Transaksi: ${transaction.id}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (storeInfo?.logoPath != null && File(storeInfo!.logoPath!).existsSync())
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Image.file(
                              File(storeInfo!.logoPath!),
                              height: 60,
                              width: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                      Center(
                        child: Text(
                          storeInfo?.toko ?? 'Nama Toko Anda',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (storeInfo?.address != null && storeInfo!.address!.isNotEmpty)
                        Center(
                          child: Text(
                            storeInfo!.address!,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (storeInfo?.phoneNumber != null && storeInfo!.phoneNumber!.isNotEmpty)
                        Center(
                          child: Text(
                            'Telp: ${storeInfo!.phoneNumber!}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),

                      const Text(
                        'STRUK PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(thickness: 2, height: 20),

                      _buildReceiptInfo('Tanggal Transaksi:', _dateFormatter.format(transaction.transactionDate.toLocal())),
                      _buildReceiptInfo('ID Transaksi:', transaction.id),
                      if (customer != null && customer?.id != 'umum')
                        _buildReceiptInfo('Pelanggan:', customer!.name),
                      const SizedBox(height: 16),

                      const Text(
                        'Daftar Belanja:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} (${item.quantity.toStringAsFixed(0)}x Rp. ${_currencyFormatter.format(item.priceAtSale)})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  'Rp ${_currencyFormatter.format(item.subtotal)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(thickness: 1, height: 20),
                      _buildTotalRow('Total Belanja:', transaction.totalAmount),
                      _buildTotalRow('Uang Dibayar:', paidAmount),
                      _buildTotalRow('Kembalian:', changeAmount, isChange: true),
                      const Divider(thickness: 2, height: 20),
                      // --- Menampilkan catatan/ucapan nota dari storeInfo ---
                      if (storeInfo?.notes?.isNotEmpty ?? false)
                        Center(
                          child: Text(
                            storeInfo!.notes!,
                            style: const TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        const Center(
                          child: Text(
                            'Terima kasih, Jangan lupa datang lagi yah.!', // Default jika tidak ada catatan
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),

                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo/kamoo_logo.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
                              },
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'by Kamoo App',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const Text(
                              'Aplikasi kasir mobile untuk usahamu.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tombol Lanjut Transaksi (Sekarang kembali ke HomeScreen dengan tab Transaksi)
                  SizedBox(
                    width: 53,
                    height: 53,
                    child: ElevatedButton(
                      onPressed: () {
                        // Mengganti semua rute di stack dengan HomeScreen dan mengaturnya ke tab Transaksi (index 2)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              nama: customer?.name ?? '',
                              initialIndex: 2, // Mengarahkan ke tab Transaksi
                            ),
                          ),
                          (route) => false, // Hapus semua rute sebelumnya
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                      ),
                      child: const Icon(Icons.arrow_back, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tombol Cetak Struk (Tidak ada perubahan)
                  SizedBox(
                    width: 53,
                    height: 53,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cetak Struk'),
                            content: const Text('Fungsi cetak masih dalam tahap pengembangan. Anda dapat melakukan screenshot atau membagikan struk ini.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                      ),
                      child: const Icon(Icons.print_outlined, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tombol Kembali ke Beranda (Sekarang kembali ke HomeScreen dengan tab Beranda)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Mengganti semua rute di stack dengan HomeScreen dan mengaturnya ke tab Beranda (index 0)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              nama: customer?.name ?? '',
                              initialIndex: 0, // Mengarahkan ke tab Beranda
                            ),
                          ),
                          (route) => false, // Hapus semua rute sebelumnya
                        );
                      },
                      icon: const Icon(Icons.home_outlined, size: 24),
                      label: const Text(
                        'Beranda',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}