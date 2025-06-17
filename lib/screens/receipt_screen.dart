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
        title: const Text('Detail Struk'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05), // shadow tipis
                      blurRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 20),
                        painter: SerratedEdgePainter(isTop: true),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (storeInfo?.logoPath != null &&
                                File(storeInfo!.logoPath!).existsSync())
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Image.file(
                                    File(storeInfo!.logoPath!),
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            Center(
                              child: Text(
                                storeInfo?.name ?? 'Nama Toko Anda',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (storeInfo?.address?.isNotEmpty ?? false)
                              Center(
                                child: Text(
                                  storeInfo!.address!,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (storeInfo?.phoneNumber?.isNotEmpty ?? false)
                              Center(
                                child: Text(
                                  'Telp: ${storeInfo!.phoneNumber!}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 16),
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

                            _buildReceiptInfo(
                                'Tanggal Transaksi:',
                                dateFormatter.format(
                                    transaction.transactionDate.toLocal())),
                            _buildReceiptInfo('ID Transaksi:', transaction.id),
                            if (customer != null && customer?.id != 'umum')
                              _buildReceiptInfo('Pelanggan:', customer!.name),
                            const SizedBox(height: 16),

                            const Text(
                              'Daftar Belanja:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                            _buildTotalRow(
                                'Total Belanja:', transaction.totalAmount),
                            _buildTotalRow('Uang Dibayar:', paidAmount),
                            _buildTotalRow('Kembalian:', changeAmount,
                                isChange: true),
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

                            // --- Bagian Logo Aplikasi Kamoo ---
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/logo/kamoo_logo.png', // Ganti dengan path logo Kamoo Anda
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey);
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
                                      color: Colors.blueGrey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: const Size(double.infinity, 20),
                        painter: SerratedEdgePainter(isTop: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cetak Struk'),
                          content: const Text(
                              'Fungsi cetak fisik sedang dalam pengembangan.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 26),
                    label: const Text(
                      'Cetak Struk',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.blueAccent,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
              color: isChange
                  ? (amount >= 0 ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
          Text(
            'Rp ${currencyFormatter.format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isChange ? 18 : 16,
              color: isChange
                  ? (amount >= 0 ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class SerratedEdgePainter extends CustomPainter {
  final bool isTop;
  final Color lineColor;
  final double toothWidth;
  final double toothHeight;

  SerratedEdgePainter({
    required this.isTop,
    this.lineColor = const Color(0xFFF5F5F5),
    this.toothWidth = 24.0,
    this.toothHeight = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final Path path = Path();

    if (isTop) {
      path.moveTo(0, size.height);
      double currentX = 0;
      while (currentX < size.width) {
        path.lineTo(currentX + toothWidth / 2, size.height - toothHeight);
        path.lineTo(currentX + toothWidth, size.height);
        currentX += toothWidth;
      }
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.moveTo(0, 0);
      double currentX = 0;
      while (currentX < size.width) {
        path.lineTo(currentX + toothWidth / 2, toothHeight);
        path.lineTo(currentX + toothWidth, 0);
        currentX += toothWidth;
      }
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);

    final Paint linePaint = Paint()
      ..color = Colors.transparent // hilangkan garis
      ..strokeWidth = 0
      ..style = PaintingStyle.stroke;

    if (isTop) {
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), linePaint);
    } else {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SerratedEdgePainter oldDelegate) {
    return oldDelegate.isTop != isTop ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.toothWidth != toothWidth ||
        oldDelegate.toothHeight != toothHeight;
  }
}