// lib/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // MobileScannerController controller = MobileScannerController(); // Bisa juga pakai controller
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Barcode Barang'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              // torchEnabled: true, // Opsional: nyalakan flash
              formats: [BarcodeFormat.ean13, BarcodeFormat.code128, BarcodeFormat.qrCode], // Format barcode yang didukung
            ),
            onDetect: (capture) {
              if (_isScanning) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    setState(() {
                      _isScanning = false; // Hentikan pemindaian setelah deteksi pertama
                    });
                    // Kembali ke layar sebelumnya dengan hasil barcode
                    Navigator.pop(context, code);
                  }
                }
              }
            },
          ),
          // Opsional: tambahkan overlay atau panduan
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Arahkan kamera ke barcode',
                  style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}