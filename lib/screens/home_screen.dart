import 'dart:io';
import 'package:flutter/material.dart';
import '../auth/local_auth_service.dart';
import 'login_screen.dart';
import 'product_list_screen.dart';
import 'profile_screen.dart';
import 'transaction_screen.dart';
import 'debt_screen.dart';
import 'accounting_screen.dart';
import 'customer_screen.dart';
import 'transaction_history_screen.dart';
import 'settings_screen.dart';
import '../models/transaction.dart' as app_transaction;
import '../services/transaction_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Data Models for Charts and Product Sales ---

// Model untuk data penjualan produk (teratas/terendah)
class ProductSaleData {
  final String name;
  final double soldQuantity;

  ProductSaleData({required this.name, required this.soldQuantity});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSaleData &&
        other.name == name &&
        other.soldQuantity == soldQuantity;
  }

  @override
  int get hashCode => name.hashCode ^ soldQuantity.hashCode;
}

// Model untuk titik data pada Line Chart (nilai total penjualan per tanggal)
class SalesDataPoint {
  final DateTime date;
  final double totalSalesValue; // Total nilai penjualan untuk tanggal ini

  SalesDataPoint({required this.date, required this.totalSalesValue});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesDataPoint &&
        other.date == date &&
        other.totalSalesValue == totalSalesValue;
  }

  @override
  int get hashCode => date.hashCode ^ totalSalesValue.hashCode;
}

// --- HomeScreen Class ---
class HomeScreen extends StatefulWidget {
  final String nama;
  final int? initialIndex;

  const HomeScreen({
    super.key,
    required this.nama,
    this.initialIndex,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _nama = '';
  String _toko = '';
  File? _storeLogo;
  String selectedFilter = 'Harian'; // Filter default untuk grafik dan produk

  List<ProductSaleData> _topSellingProducts = [];
  List<ProductSaleData> _leastSellingProducts = [];
  bool _isLoadingProductSales = true;

  List<SalesDataPoint> _salesLineData = []; // Data untuk line chart
  bool _isLoadingChartData = true;

  Map<String, double> _productPrices = {}; // Map untuk menyimpan harga produk

  final List<String> filters = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  final List<String> _appBarTitles = [
    'BERANDA',
    'DAFTAR BARANGKU',
    'MENU TRANSAKSI',
    'RIWAYAT TRANSAKSI',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProductPrices(); // Panggil ini untuk memuat harga produk
    _fetchProductSales(); // Ambil data produk terlaris/terendah
    _fetchSalesLineChartData(); // Ambil data untuk line chart

    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
    }
  }

  // --- Fungsi untuk memuat informasi pengguna ---
  Future<void> _loadUserInfo() async {
    final userMap = await LocalAuthService.getLoggedInUser();
    setState(() {
      _toko = userMap?['toko'] ?? '';
      _nama = userMap?['nama'] ?? 'Pengguna';
      if (userMap?['storeLogoPath'] != null) {
        _storeLogo = File(userMap!['storeLogoPath'] as String);
        if (!_storeLogo!.existsSync()) {
          _storeLogo = null;
        }
      } else {
        _storeLogo = null;
      }
    });
  }

  // --- Fungsi baru untuk memuat harga produk ke dalam map ---
  Future<void> _loadProductPrices() async {
    try {
      final products = await ProductService.getProducts();
      setState(() {
        _productPrices = {
          for (var product in products) product.name: product.price,
        };
      });
    } catch (e) {
      print('Error loading product prices: $e'); // ignore: avoid_print
    }
  }

  // --- Fungsi untuk mengambil dan mengolah data Line Chart ---
  Future<void> _fetchSalesLineChartData() async {
    setState(() {
      _isLoadingChartData = true;
      _salesLineData = [];
    });

    List<app_transaction.Transaction> transactions = [];
    try {
      transactions = await TransactionService.loadTransactions();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading transactions for line chart: $e');
      setState(() {
        _isLoadingChartData = false;
      });
      return;
    }

    // Map untuk mengelompokkan total nilai transaksi berdasarkan tanggal
    Map<DateTime, double> dailySales = {};

    DateTime now = DateTime.now();
    DateTime filterStartDate;
    DateTime filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (selectedFilter) {
      case 'Harian':
        filterStartDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Mingguan':
        filterStartDate = now.subtract(Duration(days: now.weekday - 1));
        filterStartDate = DateTime(filterStartDate.year, filterStartDate.month, filterStartDate.day);
        break;
      case 'Bulanan':
        filterStartDate = DateTime(now.year, now.month, 1);
        break;
      case 'Tahunan':
        filterStartDate = DateTime(now.year, 1, 1);
        break;
      default:
        filterStartDate = DateTime(now.year, now.month, now.day);
    }

    // Initialize dailySales with 0 for each day/period within the filter range
    for (DateTime d = filterStartDate; d.isBefore(filterEndDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      dailySales[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    for (var transaction in transactions) {
      DateTime transactionDay = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );

      if ((transactionDay.isAfter(filterStartDate) || transactionDay.isAtSameMomentAs(filterStartDate)) &&
          (transactionDay.isBefore(filterEndDate.add(const Duration(days: 1))))) {
        double transactionTotal = 0.0;
        for (var item in transaction.items) {
          final productPrice = _productPrices[item.productName] ?? 0.0;
          transactionTotal += (item.quantity * productPrice);
        }
        dailySales.update(
          transactionDay,
          (value) => value + transactionTotal,
          ifAbsent: () => transactionTotal,
        );
      }
    }

    _salesLineData = dailySales.entries
        .map((entry) => SalesDataPoint(date: entry.key, totalSalesValue: entry.value))
        .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _isLoadingChartData = false;
    });
  }

  // --- Fungsi untuk mengambil dan mengolah data produk terlaris/terendah ---
  Future<void> _fetchProductSales() async {
    setState(() {
      _isLoadingProductSales = true;
      _topSellingProducts = [];
      _leastSellingProducts = [];
    });

    List<app_transaction.Transaction> transactions = [];
    List<Product> allRegisteredProducts = [];

    try {
      transactions = await TransactionService.loadTransactions();
      allRegisteredProducts = await ProductService.getProducts();
      // ignore: avoid_print
      print('Loaded ${transactions.length} transactions from database.');
      // ignore: avoid_print
      print('Loaded ${allRegisteredProducts.length} registered products.');
    } catch (e) {
      // ignore: avoid_print
      print('Error loading data: $e');
    }

    Map<String, double> productSalesMap = {};

    DateTime now = DateTime.now();
    DateTime filterStartDate;

    switch (selectedFilter) {
      case 'Harian':
        filterStartDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Mingguan':
        filterStartDate = now.subtract(Duration(days: now.weekday - 1));
        filterStartDate = DateTime(filterStartDate.year, filterStartDate.month, filterStartDate.day);
        break;
      case 'Bulanan':
        filterStartDate = DateTime(now.year, now.month, 1);
        break;
      case 'Tahunan':
        filterStartDate = DateTime(now.year, 1, 1);
        break;
      default:
        filterStartDate = DateTime(now.year, now.month, now.day);
    }

    // Process transactions to get sales quantity
    for (var transaction in transactions) {
      if (transaction.transactionDate.isAfter(filterStartDate) ||
          transaction.transactionDate.isAtSameMomentAs(filterStartDate)) {
        for (var item in transaction.items) {
          productSalesMap.update(
            item.productName,
            (value) => value + item.quantity,
            ifAbsent: () => item.quantity,
          );
        }
      }
    }

    List<ProductSaleData> allProductsWithSalesData = [];

    // Add all registered products to the list with their sold quantities, default 0
    for (var product in allRegisteredProducts) {
      double soldQty = productSalesMap[product.name] ?? 0.0;
      allProductsWithSalesData.add(ProductSaleData(name: product.name, soldQuantity: soldQty));
    }

    // Sort for top selling products (descending by sold quantity)
    _topSellingProducts = allProductsWithSalesData
        .where((p) => p.soldQuantity > 0)
        .toList()
        ..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));
    _topSellingProducts = _topSellingProducts.take(4).toList();

    // Sort for least selling products (ascending by sold quantity), prioritizing 0 sales
    List<ProductSaleData> zeroSoldProducts = allProductsWithSalesData
        .where((p) => p.soldQuantity == 0)
        .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

    List<ProductSaleData> nonZeroLeastSelling = allProductsWithSalesData
        .where((p) => p.soldQuantity > 0)
        .toList()
        ..sort((a, b) => a.soldQuantity.compareTo(b.soldQuantity));

    List<ProductSaleData> combinedLeastSelling = [];
    combinedLeastSelling.addAll(zeroSoldProducts);

    for (var p in nonZeroLeastSelling) {
      if (!combinedLeastSelling.any((existing) => existing.name == p.name)) {
        combinedLeastSelling.add(p);
      }
      if (combinedLeastSelling.length >= 4) {
        break;
      }
    }

    _leastSellingProducts = combinedLeastSelling.take(4).toList();

    setState(() {
      _isLoadingProductSales = false;
    });
  }

  // --- Fungsi untuk navigasi BottomNavigationBar ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Fungsi untuk logout ---
  void _logout() async {
    await LocalAuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- Widget untuk bagian grafik penjualan (Line Chart) ---
  Widget buildSalesChartSection() {
    double chartMaxY = 0;
    if (_salesLineData.isNotEmpty) {
      chartMaxY = _salesLineData.map((p) => p.totalSalesValue).reduce((a, b) => a > b ? a : b) * 1.2;
      if (chartMaxY == 0) chartMaxY = 100.0;
    } else {
      chartMaxY = 100.0;
    }

    // Determine X-axis interval based on selected filter
    double intervalX;
    if (selectedFilter == 'Harian' || selectedFilter == 'Mingguan') {
      intervalX = 1.0;
    } else if (selectedFilter == 'Bulanan') {
      intervalX = 7.0;
    } else { // Tahunan
      intervalX = 30.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grafik Penjualan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedFilter,
                items: filters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedFilter = value);
                    _fetchProductSales();
                    _fetchSalesLineChartData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingChartData
              ? Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : _salesLineData.isEmpty
                  ? Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('Tidak ada data penjualan untuk grafik.')),
                    )
                  : SizedBox(
                      height: 200, // Adjust height as needed
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: (chartMaxY / 5).roundToDouble() > 0 ? (chartMaxY / 5).roundToDouble() : 10.0,
                            verticalInterval: intervalX,
                            getDrawingHorizontalLine: (value) => const FlLine(
                              color: Color(0xff37434d),
                              strokeWidth: 0.1,
                            ),
                            getDrawingVerticalLine: (value) => const FlLine(
                              color: Color(0xff37434d),
                              strokeWidth: 0.1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, TitleMeta meta) {
                                  if (value.toInt() < _salesLineData.length) {
                                    final date = _salesLineData[value.toInt()].date;
                                    String formattedDate;
                                    if (selectedFilter == 'Harian' || selectedFilter == 'Mingguan') {
                                      formattedDate = '${date.day}/${date.month}';
                                    } else if (selectedFilter == 'Bulanan') {
                                      formattedDate = '${date.day}/${date.month}';
                                    } else { // Tahunan
                                      formattedDate = '${date.month}/${date.year}';
                                    }
                                    // Langsung kembalikan Text widget, tanpa SideTitleWidget
                                    return Padding( // Gunakan Padding untuk spasi
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                interval: intervalX,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, TitleMeta meta) {
                                  return Text(
                                    value.toStringAsFixed(0),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                interval: (chartMaxY / 5).roundToDouble() > 0 ? (chartMaxY / 5).roundToDouble() : 10.0,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: const Color(0xff37434d), width: 1),
                          ),
                          minX: 0,
                          maxX: (_salesLineData.length - 1).toDouble(),
                          minY: 0,
                          maxY: chartMaxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _salesLineData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return FlSpot(index.toDouble(), data.totalSalesValue);
                              }).toList(),
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.blue.shade800,
                                ],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(
                                show: false,
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade300,
                                    Colors.blue.shade800,
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final dataPoint = _salesLineData[spot.spotIndex];
                                  String formattedDate;
                                  if (selectedFilter == 'Harian' || selectedFilter == 'Mingguan') {
                                    formattedDate = '${dataPoint.date.day}/${dataPoint.date.month}';
                                  } else if (selectedFilter == 'Bulanan') {
                                    formattedDate = '${dataPoint.date.day}/${dataPoint.date.month}';
                                  } else { // Tahunan
                                    formattedDate = '${dataPoint.date.month}/${dataPoint.date.year}';
                                  }

                                  return LineTooltipItem(
                                    '$formattedDate: Rp ${dataPoint.totalSalesValue.toStringAsFixed(0)}',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  // --- Widget untuk bagian produk terlaris dan kurang laku ---
  Widget buildTopAndBottomProducts() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Produk Paling Laku', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _isLoadingProductSales
              ? const Center(child: CircularProgressIndicator())
              : _topSellingProducts.isEmpty
                  ? const Center(child: Text('Tidak ada data produk paling laku untuk saat ini.'))
                  : Column(
                      children: _topSellingProducts.map((p) => ListTile(
                                leading: const Icon(Icons.trending_up, color: Colors.green),
                                title: Text(p.name),
                                trailing: Text('${p.soldQuantity.toStringAsFixed(0)} terjual'),
                              )).toList(),
                    ),
          const SizedBox(height: 16),
          const Text('Produk Kurang Laku', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _isLoadingProductSales
              ? const Center(child: CircularProgressIndicator())
              : _leastSellingProducts.isEmpty
                  ? const Center(child: Text('Tidak ada data produk kurang laku untuk saat ini.'))
                  : Column(
                      children: _leastSellingProducts.map((p) => ListTile(
                                leading: const Icon(Icons.trending_down, color: Colors.red),
                                title: Text(p.name),
                                trailing: Text('${p.soldQuantity.toStringAsFixed(0)} terjual'),
                              )).toList(),
                    ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = [
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTopAndBottomProducts(),
            buildSalesChartSection(),
          ],
        ),
      ),
      const ProductListScreen(),
      const TransactionScreen(),
      const TransactionHistoryScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: _storeLogo != null ? FileImage(_storeLogo!) : null,
                      child: _storeLogo == null
                          ? const Icon(Icons.storefront, size: 40, color: Color(0xFF084FEA))
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _toko,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Halo, $_nama!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil'),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                _loadUserInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.join_right_outlined),
              title: const Text('Hutang'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Pembukuan'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountingScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Pelanggan'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Bantuan'),
              // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kamoo App',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
              BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
              BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Transaksi'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
            ],
            currentIndex: _selectedIndex,
            backgroundColor: Colors.blue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}