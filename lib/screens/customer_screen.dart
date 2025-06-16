import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../services/data_manager.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

// Tidak perlu enum TransactionFilterPeriod lagi jika hanya ada tanggal kustom
// atau semua transaksi.

class _CustomerScreenState extends State<CustomerScreen> with WidgetsBindingObserver {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Uuid _uuid = const Uuid();

  // Hanya menggunakan tanggal mulai dan akhir untuk filter
  // Default: menampilkan transaksi 30 hari terakhir.
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inisialisasi filter tanggal ke 30 hari terakhir secara default
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate!.subtract(const Duration(days: 29)); // 30 hari terakhir
    
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers() async {
    final loadedCustomers = await DataManager.loadCustomers();
    if (mounted) {
      setState(() {
        _customers = loadedCustomers;
        _filterCustomers();
      });
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
               customer.phoneNumber.toLowerCase().contains(query);
      }).toList();
    });
  }

  List<Transaction> _filterTransactionsByDateRange(List<Transaction> transactions, DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return transactions; // Jika tidak ada tanggal yang dipilih, tampilkan semua
    }

    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    // Tambahkan 1 hari untuk endDate agar mencakup seluruh hari terakhir
    final endOfNextDay = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    return transactions.where((transaction) {
      final transactionDate = transaction.transactionDate.toLocal();
      return transactionDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
             transactionDate.isBefore(endOfNextDay);
    }).toList();
  }

  Future<Map<String, dynamic>> _loadCustomerTransactionHistory(String customerId) async {
    try {
      final allTransactions = await TransactionService.loadTransactions();
      List<Transaction> customerTransactions = allTransactions
          .where((transaction) => transaction.customerId == customerId)
          .toList();

      // Gunakan _filterTransactionsByDateRange dengan _filterStartDate dan _filterEndDate
      customerTransactions = _filterTransactionsByDateRange(customerTransactions, _filterStartDate, _filterEndDate);

      List<String> historySummaries = [];
      double totalOverallSales = 0.0;

      customerTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      for (var transaction in customerTransactions) {
        final transactionTotal = transaction.items.fold(0.0, (sum, item) => sum + (item.quantity * item.priceAtSale));
        historySummaries.add(
            '${DateFormat('dd/MM/yyyy, HH:mm').format(transaction.transactionDate.toLocal())} - Rp. ${NumberFormat('#,###', 'id_ID').format(transactionTotal)} (${transaction.items.length} item)'
        );
        totalOverallSales += transactionTotal;
      }
      return {
        'summaries': historySummaries,
        'totalSales': totalOverallSales,
      };
    } catch (e) {
      return {
        'summaries': ['Gagal memuat riwayat transaksi: $e'],
        'totalSales': 0.0,
      };
    }
  }

  void _showCustomSnackbar(String message, {bool isSuccess = true}) {
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addCustomer() async {
    if (_nameController.text.isEmpty || _phoneNumberController.text.isEmpty) {
      _showCustomSnackbar('Nama dan Nomor Telepon harus diisi!', isSuccess: false);
      return;
    }

    final newCustomer = Customer(
      id: _uuid.v4(),
      name: _nameController.text,
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
    );

    setState(() {
      _customers.add(newCustomer);
      _filterCustomers();
    });
    await DataManager.saveCustomers(_customers);
    _nameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    if (mounted) {
      Navigator.of(context).pop();
      _showCustomSnackbar('Pelanggan berhasil ditambahkan!');
    }
  }

  Future<void> _editCustomer(Customer customerToEdit) async {
    if (_nameController.text.isEmpty || _phoneNumberController.text.isEmpty) {
      _showCustomSnackbar('Nama dan Nomor Telepon harus diisi!', isSuccess: false);
      return;
    }

    final updatedCustomer = Customer(
      id: customerToEdit.id,
      name: _nameController.text,
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
    );

    setState(() {
      final index = _customers.indexWhere((c) => c.id == customerToEdit.id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
        _filterCustomers();
      }
    });
    await DataManager.saveCustomers(_customers);
    _nameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    if (mounted) {
      Navigator.of(context).pop();
      _showCustomSnackbar('Pelanggan berhasil diperbarui!');
    }
  }

  Future<void> _deleteCustomer(String customerId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Pelanggan?'),
          content: const Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _customers.removeWhere((c) => c.id == customerId);
                  _filterCustomers();
                });
                await DataManager.saveCustomers(_customers);
                if (!mounted) return;
                Navigator.of(context).pop();
                _showCustomSnackbar('Pelanggan berhasil dihapus.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCustomerModal({Customer? customer}) {
    bool isEditing = customer != null;
    _nameController.text = isEditing ? customer.name : '';
    _phoneNumberController.text = isEditing ? customer.phoneNumber : '';
    _addressController.text = isEditing ? customer.address : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.person_add_alt_1,
                        size: 36,
                        color: const Color(0xFF084FEA),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan Baru',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField('Nama Pelanggan', Icons.person, _nameController),
                const SizedBox(height: 12),
                _buildInputField(
                  'Nomor Telepon',
                  Icons.phone,
                  _phoneNumberController,
                  inputType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                _buildInputField('Alamat (Opsional)', Icons.location_on, _addressController),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      onPressed: isEditing ? () => _editCustomer(customer) : _addCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(isEditing ? 'Simpan' : 'Tambah'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Bisa sampai 1 tahun ke depan
      initialDateRange: (_filterStartDate != null && _filterEndDate != null)
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
      // Pemicu rebuild FutureBuilder melalui setState
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        // Hapus actions jika tidak ada ikon filter di AppBar lagi
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Pelanggan...',
                hintText: 'Ketik Nama/Nomor Telepon',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // Bagian filter periode seperti yang diinginkan
          GestureDetector(
            onTap: _pickDateRange, // Ketika area ini ditekan, buka date picker
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _filterStartDate != null && _filterEndDate != null
                          ? 'Periode: ${DateFormat('dd/MM/yyyy').format(_filterStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_filterEndDate!)}'
                          : 'Pilih Periode Tanggal', // Teks jika belum ada tanggal terpilih
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Text(
                    _filterStartDate != null && _filterEndDate != null ? 'Ubah' : 'Pilih',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _filteredCustomers.isEmpty
                ? Center(
                    child: Text(_searchController.text.isEmpty
                        ? 'Belum ada data pelanggan.'
                        : 'Tidak ada pelanggan ditemukan.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(customer.phoneNumber),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showCustomerModal(customer: customer),
                                tooltip: 'Edit Pelanggan',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCustomer(customer.id),
                                tooltip: 'Hapus Pelanggan',
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📍 Alamat: ${customer.address.isEmpty ? '-' : customer.address}'),
                                  const SizedBox(height: 8),
                                  const Text('🧾 Riwayat Belanja:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  FutureBuilder<Map<String, dynamic>>(
                                    // Tidak perlu lagi parameter period, karena sudah diatur oleh _filterStartDate/_filterEndDate
                                    future: _loadCustomerTransactionHistory(customer.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ));
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else if (!snapshot.hasData || (snapshot.data!['summaries'] as List).isEmpty) {
                                        return const Text('Tidak ada riwayat belanja untuk periode ini.');
                                      } else {
                                        final summaries = snapshot.data!['summaries'] as List<String>;
                                        final totalSales = snapshot.data!['totalSales'] as double;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ...summaries.map((history) => ListTile(
                                                  dense: true,
                                                  visualDensity: const VisualDensity(vertical: -4),
                                                  leading: const Icon(Icons.shopping_bag_outlined, size: 16),
                                                  title: Text(history, style: const TextStyle(fontSize: 14)),
                                                )),
                                            const Divider(height: 16, thickness: 1),
                                            Text(
                                              'Total belanja: Rp. ${NumberFormat('#,###', 'id_ID').format(totalSales)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerModal(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}