// lib/screens/accounting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/account_entry.dart';
import '../services/accounting_service.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  List<AccountEntry> _allFilteredEntries = [];
  double _totalOtherIncome = 0.0;
  double _totalSales = 0.0;
  double _totalExpense = 0.0;
  double _profit = 0.0;

  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccountingData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountingData() async {
    setState(() {
      _allFilteredEntries = [];
    });

    final currentTotalOtherIncome = await AccountingService.getTotalOtherIncome(
        startDate: _selectedStartDate, endDate: _selectedEndDate);
    final currentTotalSales = await AccountingService.getTotalSalesFromTransactions(
        startDate: _selectedStartDate, endDate: _selectedEndDate);
    final currentTotalExpense = await AccountingService.getTotalExpense(
        startDate: _selectedStartDate, endDate: _selectedEndDate);
    final calculatedProfit = await AccountingService.calculateProfit(
        startDate: _selectedStartDate, endDate: _selectedEndDate);

    final allEntries = await AccountingService.getAllEntries(
        startDate: _selectedStartDate, endDate: _selectedEndDate);
    allEntries.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _totalOtherIncome = currentTotalOtherIncome;
        _totalSales = currentTotalSales;
        _totalExpense = currentTotalExpense;
        _profit = calculatedProfit;
        _allFilteredEntries = allEntries;
      });
    }
  }

  void _showCustomSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _addEntry(AccountEntryType type) async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      _showCustomSnackBar(
        'Deskripsi dan Jumlah harus diisi!',
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showCustomSnackBar(
        'Jumlah harus berupa angka positif!',
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    final newEntry = AccountEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      description: _descriptionController.text,
      amount: amount,
      date: DateTime.now(),
      type: type,
    );

    try {
      if (type == AccountEntryType.income) {
        await AccountingService.addIncomeEntry(newEntry);
      } else {
        await AccountingService.addExpenseEntry(newEntry);
      }

      _descriptionController.clear();
      _amountController.clear();
      if (mounted) {
        Navigator.of(context).pop();
        _loadAccountingData();
        _showCustomSnackBar(
          '${type == AccountEntryType.income ? "Pemasukan" : "Pengeluaran"} berhasil ditambahkan!',
          Colors.green,
          Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          'Gagal menambahkan entri: $e',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  Future<void> _editEntry(AccountEntry entryToEdit) async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      _showCustomSnackBar(
        'Deskripsi dan Jumlah harus diisi!',
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showCustomSnackBar(
        'Jumlah harus berupa angka positif!',
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    final updatedEntry = AccountEntry(
      id: entryToEdit.id,
      description: _descriptionController.text,
      amount: amount,
      date: entryToEdit.date,
      type: entryToEdit.type,
    );

    try {
      if (entryToEdit.type == AccountEntryType.income) {
        await AccountingService.editIncomeEntry(updatedEntry);
      } else {
        await AccountingService.editExpenseEntry(updatedEntry);
      }

      _descriptionController.clear();
      _amountController.clear();
      if (mounted) {
        Navigator.of(context).pop();
        _loadAccountingData();
        _showCustomSnackBar(
          '${entryToEdit.type == AccountEntryType.income ? "Pemasukan" : "Pengeluaran"} berhasil diperbarui!',
          Colors.green,
          Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          'Gagal memperbarui entri: $e',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  Future<void> _deleteEntry(AccountEntry entryToDelete) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Entri?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin menghapus entri ini: "${entryToDelete.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (entryToDelete.type == AccountEntryType.income) {
                    await AccountingService.deleteIncomeEntry(entryToDelete.id);
                  } else {
                    await AccountingService.deleteExpenseEntry(entryToDelete.id);
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _loadAccountingData();
                  _showCustomSnackBar(
                    '${entryToDelete.type == AccountEntryType.income ? "Pemasukan" : "Pengeluaran"} berhasil dihapus.',
                    Colors.green,
                    Icons.check_circle,
                  );
                } catch (e) {
                  if (mounted) {
                    _showCustomSnackBar(
                      'Gagal menghapus entri: $e',
                      Colors.red,
                      Icons.error,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  void _showEntryModal({AccountEntry? entry, required AccountEntryType type}) {
    bool isEditing = entry != null;
    _descriptionController.text = isEditing ? entry.description : '';
    _amountController.text = isEditing ? NumberFormat('#,###', 'id_ID').format(entry.amount).replaceAll('.', '') : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
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
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing
                      ? type == AccountEntryType.income ? "Edit Pemasukan" : "Edit Pengeluaran"
                      : type == AccountEntryType.income ? "Tambah Pemasukan" : "Tambah Pengeluaran",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah (Rp)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixText: 'Rp. ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isEditing ? () => _editEntry(entry) : () => _addEntry(type),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type == AccountEntryType.income ? Colors.green : Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Simpan' : 'Tambah',
                        style: const TextStyle(color: Colors.white),
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
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _selectedStartDate, end: _selectedEndDate),
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF084FEA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && (picked.start != _selectedStartDate || picked.end != _selectedEndDate)) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _loadAccountingData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembukuan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                // Bagian Periode
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Bagian Periode
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Periode: ${DateFormat('dd/MM/yyyy', 'id_ID').format(_selectedStartDate)} - ${DateFormat('dd/MM/yyyy', 'id_ID').format(_selectedEndDate)}',
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _selectDateRange,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                            ),
                            child: const Text('Ubah', style: TextStyle(color: Color(0xFF084FEA))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Bagian Detail Pemasukan
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Pemasukan dari penjualan:', style: TextStyle(color: Colors.black)),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(_totalSales)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Pemasukan Lain-lain:', style: TextStyle(color: Colors.black)),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(_totalOtherIncome)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const Divider(height: 16, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pemasukan:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(_totalOtherIncome + _totalSales)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bagian Pengeluaran
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pengeluaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(_totalExpense)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bagian Keuntungan Bersih
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _profit >= 0 ? Colors.blue.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Keuntungan Bersih:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(_profit)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _profit >= 0 ? Colors.blue : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Tombol Aksi
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showEntryModal(type: AccountEntryType.income),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text('Pemasukan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showEntryModal(type: AccountEntryType.expense),
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              label: const Text('Pengeluaran'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, size: 18, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Pembukuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${_allFilteredEntries.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allFilteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada riwayat pembukuan, yuk mulai mencatat!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _allFilteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _allFilteredEntries[index];
                      final isIncome = entry.type == AccountEntryType.income;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ikon kiri bulat
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info utama
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.description,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMMM yyyy • HH:mm', 'id_ID').format(entry.date),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            // Nominal dan icon edit/delete
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} Rp${NumberFormat('#,###', 'id_ID').format(entry.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16),
                                      onPressed: () => _showEntryModal(entry: entry, type: entry.type),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16),
                                      onPressed: () => _deleteEntry(entry),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),


          ),
        ],
      ),
    );
  }
}