// lib/screens/receipt_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';
import '../models/customer.dart';
import '../models/store_info.dart';

class ReceiptScreen extends StatelessWidget {
  final app_transaction.Transaction transaction;
  final List<TransactionItem> items;
  final Customer? customer;
  final double paidAmount;
  final double changeAmount;
  final StoreInfo? storeInfo;

  const ReceiptScreen({
    super.key,
    required this.transaction,
    required this.items,
    this.customer,
    required this.paidAmount,
    required this.changeAmount,
    this.storeInfo,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat('#,###', 'id_ID');
    final DateFormat dateFormatter = DateFormat('dd MMMM HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Struk'), // Ubah judul agar lebih sesuai
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Ubah dari Card langsung ke Column
          children: [
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
                    // --- Bagian Header Struk (Logo Toko, Nama Toko, Alamat, Nomor) ---
                    if (storeInfo?.logoPath != null && File(storeInfo!.logoPath!).existsSync())
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Image.file(
                            File(storeInfo!.logoPath!),
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    Center(
                      child: Text(
                        storeInfo?.name ?? 'Nama Toko Anda',
                        style: const TextStyle(
                          fontSize: 22,
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
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (storeInfo?.phoneNumber != null && storeInfo!.phoneNumber!.isNotEmpty)
                      Center(
                        child: Text(
                          'Telp: ${storeInfo!.phoneNumber!}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // -----------------------------------------------------------

                    const Text(
                      'STRUK PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(thickness: 2, height: 20),

                    _buildReceiptInfo('Tanggal Transaksi:', dateFormatter.format(transaction.transactionDate.toLocal())),
                    _buildReceiptInfo('ID Transaksi:', transaction.id),
                    if (customer != null && customer?.id != 'umum')
                      _buildReceiptInfo('Pelanggan:', customer!.name),
                    const SizedBox(height: 16),

                    const Text(
                      'Daftar Belanja:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  '${item.productName} (${item.quantity.toStringAsFixed(0)}x Rp ${currencyFormatter.format(item.priceAtSale)})',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              Text(
                                'Rp ${currencyFormatter.format(item.subtotal)}',
                                style: const TextStyle(fontSize: 15),
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
                    const Center(
                      child: Text(
                        'Terima kasih, Jangan lupa mampir lagi yah.!',
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Bagian Logo Aplikasi Kamoo ---
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/logo/kamoo_logo.png', // Ganti dengan path logo Kamoo Anda
                            height: 50,
                            width: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'by Kamoo App',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const Text(
                            'Aplikasi kasir mobile untuk usahamu.',
                            style: TextStyle(
                              fontSize: 12,
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
            const SizedBox(height: 24), // Memberi jarak antara Card struk dan tombol

            // --- Tombol Cetak Struk (Pengingat), sekarang di luar Card ---
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7, // 70% lebar layar
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cetak Struk'),
                        content: const Text('Fungsi cetak fisik sedang dalam pengembangan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 24),
                  label: const Text(
                    'Cetak Struk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Spasi di bagian paling bawah halaman
          ],
        ),
      ),
    );
  }

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
    final NumberFormat currencyFormatter = NumberFormat('#,###', 'id_ID');

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
            'Rp ${currencyFormatter.format(amount)}',
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
}