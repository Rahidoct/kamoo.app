import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../models/debt_transaction.dart'; // Import model transaksi
import '../services/data_manager.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  List<Debt> _debts = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDueDate;
  String _selectedStatus = 'Belum Lunas';

  Debt? _editingDebt;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final debts = await DataManager.loadDebts();
    setState(() {
      _debts = debts;
    });
  }

  Future<void> _saveDebts() async {
    await DataManager.saveDebts(_debts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final totalDebt = _debts
      .where((d) => d.status != 'Lunas')
      .fold(0.0, (sum, debt) => sum + debt.amount);
  final overdueDebts = _debts
      .where((d) => d.dueDate.isBefore(DateTime.now()) && d.status != 'Lunas')
      .length;

  final debtsToDisplay = _searchController.text.isEmpty
      ? _debts
      : _debts
          .where((d) => d.customerName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Hutang'),
        backgroundColor: const Color(0xFF084FEA),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Biru muda lembut
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey,
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama pengutang...',
                hintStyle: const TextStyle(color: Colors.blueGrey),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: const TextStyle(color: Colors.black87),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),


        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              _buildSummaryCard(
                'Total Hutang',
                'Rp ${NumberFormat('#,###', 'id_ID').format(totalDebt)}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildSummaryCard(
                'Jatuh Tempo',
                overdueDebts.toString(),
                Colors.red,
              ),
            ],
          ),
        ),

        

        // Debt List
        Expanded(
          child: debtsToDisplay.isEmpty
              ? const Center(child: Text('Tidak ada data hutang.'))
              : ListView.builder(
                  itemCount: debtsToDisplay.length,
                  itemBuilder: (context, index) {
                    final debt = debtsToDisplay[index];
                    return _buildDebtCard(debt);
                  },
                ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showAddEditDebtModal(context),
      backgroundColor: const Color(0xFF084FEA),
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    ),
  );
}

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
  final isOverdue = debt.dueDate.isBefore(DateTime.now()) && debt.status != 'Lunas';
  final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  // Status colors
  final statusConfig = {
    'Lunas': Colors.green.shade700,
    'Sebagian Lunas': Colors.orange.shade700,
    'Jatuh Tempo': Colors.red.shade700,
    'Belum Lunas': Colors.blueGrey.shade700,
  };

  final statusColor = statusConfig[debt.status] ?? Colors.blueGrey.shade700;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    elevation: 2,
    shadowColor: Colors.blueGrey,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    color: isOverdue ? Colors.red.shade50 : Colors.white,
    child: InkWell(
      onTap: () => _showDebtHistoryDialog(debt),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    debt.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp. ${NumberFormat('#,###', 'id_ID').format(debt.amount)} • ${debt.status}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jatuh Tempo: ${dateFormat.format(debt.dueDate)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red.shade700 : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  if (debt.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Catatan: ${debt.notes}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Edit Hutang',
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: Colors.blue.shade700,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showAddEditDebtModal(context, debt: debt),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Tooltip(
                    message: 'Hapus Hutang',
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.red.shade700,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteDebt(debt),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showAddEditDebtModal(BuildContext context, {Debt? debt}) {
    _editingDebt = debt;

    if (_editingDebt != null) {
      _customerController.text = _editingDebt!.customerName;
      // --- PERUBAHAN DI SINI ---
      // Format double menjadi string tanpa .0 jika itu bilangan bulat
      _amountController.text = _editingDebt!.amount.toStringAsFixed(
          _editingDebt!.amount.truncateToDouble() == _editingDebt!.amount ? 0 : 2
      );
      // --- AKHIR PERUBAHAN ---
      _notesController.text = _editingDebt!.notes;
      _selectedDueDate = _editingDebt!.dueDate;
      _selectedStatus = _editingDebt!.status;
    } else {
      _customerController.clear();
      _amountController.clear();
      _notesController.clear();
      _selectedDueDate = DateTime.now().add(const Duration(days: 30));
      _selectedStatus = 'Belum Lunas';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setStateInternal) {
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingDebt == null ? 'Tambah Hutang Baru' : 'Edit Hutang',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customerController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pelanggan',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama pelanggan harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Hutang',
                            prefixText: 'Rp. ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah hutang harus diisi';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Masukkan angka yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(
                            'Jatuh Tempo: ${_selectedDueDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!) : 'Pilih Tanggal'}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (selectedDate != null) {
                              setStateInternal(() {
                                _selectedDueDate = selectedDate;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          items: ['Belum Lunas', 'Sebagian Lunas', 'Lunas', 'Jatuh Tempo']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setStateInternal(() {
                              _selectedStatus = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final newDebtAmount = double.parse(_amountController.text);

                                if (_editingDebt == null) {
                                  // Tambah Hutang Baru
                                  final newDebt = Debt(
                                    id: _uuid.v4(),
                                    customerName: _customerController.text,
                                    amount: newDebtAmount,
                                    date: DateTime.now(),
                                    dueDate: _selectedDueDate!,
                                    status: _selectedStatus,
                                    notes: _notesController.text,
                                    transactions: [
                                      DebtTransaction(
                                        id: _uuid.v4(),
                                        date: DateTime.now(),
                                        amount: newDebtAmount,
                                        type: 'Berikan',
                                        notes: _notesController.text.isNotEmpty
                                            ? _notesController.text
                                            : 'Pemberian hutang awal',
                                      ),
                                    ],
                                  );
                                  setState(() {
                                    _debts.add(newDebt);
                                  });
                                } else {
                                  // Update Hutang yang Ada
                                  final updatedDebt = _editingDebt!.copyWith(
                                    customerName: _customerController.text,
                                    amount: newDebtAmount,
                                    dueDate: _selectedDueDate,
                                    status: _selectedStatus,
                                    notes: _notesController.text,
                                  );
                                  setState(() {
                                    final index = _debts.indexWhere((d) => d.id == updatedDebt.id);
                                    if (index != -1) {
                                      _debts[index] = updatedDebt;
                                    }
                                  });
                                }
                                await _saveDebts();
                                if (mounted) Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF084FEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(_editingDebt == null ? 'Simpan' : 'Update'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDeleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Anda yakin ingin menghapus hutang dari ${debt.customerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _debts.removeWhere((d) => d.id == debt.id);
                });
                await _saveDebts();
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markDebtAsPaidOff(Debt debt) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pelunasan'),
          content: Text('Anda yakin ingin melunasi seluruh hutang Rp ${NumberFormat('#,###', 'id_ID').format(debt.amount)} dari ${debt.customerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Ya, Lunas', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final int index = _debts.indexWhere((d) => d.id == debt.id);

      if (index != -1) {
        final newTransaction = DebtTransaction(
          id: _uuid.v4(),
          date: DateTime.now(),
          amount: debt.amount,
          type: 'Terima',
          notes: 'Alhamdulillah, hutangnya sudah lunas..',
        );

        final updatedDebt = _debts[index].copyWith(
          amount: 0,
          status: 'Lunas',
          transactions: List.from(_debts[index].transactions)..add(newTransaction),
        );

        updatedDebt.transactions.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _debts[index] = updatedDebt;
        });

        await _saveDebts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hutang dari ${debt.customerName} berhasil dilunasi!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DebtScreen()),
          );
        }
      }
    }
  }

  void _showDebtHistoryDialog(Debt debt) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInternal) {
            final currentDebt = _debts.firstWhere((d) => d.id == debt.id);

            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    currentDebt.customerName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF084FEA),
                ),
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Hutang ${currentDebt.customerName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${NumberFormat('#,###', 'id_ID').format(currentDebt.amount)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                currentDebt.status,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: currentDebt.status == 'Lunas' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 1,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Fungsi Laporan Belum Diimplementasikan')),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.download, color: Colors.grey),
                                      Text('Laporan', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              elevation: 1,
                              child: InkWell(
                                onTap: () async {
                                  Navigator.pop(context); // Close history dialog
                                  await _markDebtAsPaidOff(currentDebt);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      Text('Lunaskan', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text('Tanggal',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1,
                              child: Text('Terima',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1,
                              child: Text('Berikan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: currentDebt.transactions.isEmpty
                          ? const Center(child: Text('Tidak ada riwayat transaksi.'))
                          : ListView.builder(
                              itemCount: currentDebt.transactions.length,
                              itemBuilder: (context, i) {
                                final transaction = currentDebt.transactions[i];
                                final dateFormat = DateFormat('dd MMM yyyy'); // Corrected typo
                                final amountFormat = NumberFormat('#,###', 'id_ID');

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(dateFormat.format(transaction.date)),
                                            if (transaction.notes != null && transaction.notes!.isNotEmpty)
                                              Text(
                                                transaction.notes!,
                                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          transaction.type == 'Terima'
                                              ? 'Rp${amountFormat.format(transaction.amount)}'
                                              : '-',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.green[700]),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          transaction.type == 'Berikan'
                                              ? 'Rp${amountFormat.format(transaction.amount)}'
                                              : '-',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Close history dialog
                                _showAddTransactionDialog(context,
                                    debt: currentDebt, transactionType: 'Berikan');
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('Berikan'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Close history dialog
                                _showAddTransactionDialog(context,
                                    debt: currentDebt, transactionType: 'Terima');
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Terima'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context,
      {required Debt debt, required String transactionType}) {
    final TextEditingController transactionAmountController = TextEditingController();
    final TextEditingController transactionNotesController = TextEditingController();
    final transactionFormKey = GlobalKey<FormState>();

    String dialogTitleText = transactionType == 'Terima' ? 'Catat Pembayaran' : 'Catat Pemberian Hutang';
    Color buttonColor = transactionType == 'Terima' ? Colors.green : Colors.red;
    IconData dialogIcon = transactionType == 'Terima' ? Icons.payments : Icons.send_to_mobile; // Choose appropriate icon
    Color iconColor = transactionType == 'Terima' ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners
          titlePadding: EdgeInsets.zero, // Remove default title padding
          contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Adjust content padding
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Adjust actions padding
          title: Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                dialogIcon,
                color: iconColor,
                size: 60,
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  dialogTitleText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Darker color for title
                  ),
                ),
              ),
              const Divider(thickness: 1, indent: 20, endIndent: 20), // A visual separator
            ],
          ),
          content: Form(
            key: transactionFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
              children: [
                Text(
                  'Untuk: ${debt.customerName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                Text(
                  'Sisa Hutang Saat Ini: Rp ${NumberFormat('#,###', 'id_ID').format(debt.amount)}',
                  style: const TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: transactionAmountController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah ${transactionType == 'Terima' ? 'Pembayaran' : 'Hutang'}',
                    border: const OutlineInputBorder(), // Add border
                    prefixText: 'Rp ', // Add currency prefix
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah harus diisi';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Masukkan angka positif yang valid';
                    }
                    if (transactionType == 'Terima' && amount > debt.amount) {
                      return 'Jumlah pembayaran tidak boleh melebihi sisa hutang';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: transactionNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Transaksi (Opsional)',
                    border: OutlineInputBorder(), // Add border
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute buttons evenly
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey, // Softer color for cancel
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (transactionFormKey.currentState!.validate()) {
                        final transactionAmount = double.parse(transactionAmountController.text);

                        final newTransaction = DebtTransaction(
                          id: _uuid.v4(),
                          date: DateTime.now(),
                          amount: transactionAmount,
                          type: transactionType,
                          notes: transactionNotesController.text,
                        );

                        final int debtIndex = _debts.indexWhere((d) => d.id == debt.id);
                        if (debtIndex != -1) {
                          Debt updatedDebt = _debts[debtIndex];
                          double newDebtAmount = updatedDebt.amount;

                          if (transactionType == 'Terima') {
                            newDebtAmount -= transactionAmount;
                          } else {
                            newDebtAmount += transactionAmount;
                          }

                          String newStatus = updatedDebt.status;
                          if (newDebtAmount <= 0) {
                            newStatus = 'Lunas';
                            newDebtAmount = 0;
                          } else if (newDebtAmount > 0 && updatedDebt.amount != newDebtAmount && updatedDebt.status == 'Lunas') {
                            newStatus = 'Sebagian Lunas';
                          } else if (newDebtAmount > 0 && transactionType == 'Terima') {
                            newStatus = 'Sebagian Lunas';
                          }

                          updatedDebt = updatedDebt.copyWith(
                            amount: newDebtAmount,
                            status: newStatus,
                            transactions: List.from(updatedDebt.transactions)..add(newTransaction),
                          );

                          updatedDebt.transactions.sort((a, b) => b.date.compareTo(a.date));

                          setState(() {
                            _debts[debtIndex] = updatedDebt;
                          });
                          await _saveDebts();
                          if (mounted) {
                            Navigator.pop(context);
                            _showDebtHistoryDialog(updatedDebt);
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}