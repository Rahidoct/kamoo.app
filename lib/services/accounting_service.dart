// lib/services/accounting_service.dart
import 'dart:convert'; // Tetap butuh ini untuk json.encode dan json.decode
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_entry.dart';
import 'transaction_service.dart'; // Untuk mendapatkan data transaksi

class AccountingService {
  static const String _incomeKey = 'incomeEntries';
  static const String _expenseKey = 'expenseEntries';

  // Helper untuk mendapatkan SharedPreferences instance
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Fungsi untuk memuat semua entri pemasukan
  static Future<List<AccountEntry>> loadIncomeEntries() async {
    final prefs = await _getPrefs();
    final String? incomeString = prefs.getString(_incomeKey);
    if (incomeString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(incomeString);
    return jsonList.map((json) => AccountEntry.fromJson(json)).toList();
  }

  // Fungsi untuk memuat semua entri pengeluaran
  static Future<List<AccountEntry>> loadExpenseEntries() async {
    final prefs = await _getPrefs();
    final String? expenseString = prefs.getString(_expenseKey);
    if (expenseString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(expenseString);
    return jsonList.map((json) => AccountEntry.fromJson(json)).toList();
  }

  // Fungsi untuk menyimpan daftar entri pemasukan
  static Future<void> saveIncomeEntries(List<AccountEntry> incomes) async {
    final prefs = await _getPrefs();
    final String jsonString = json.encode(incomes.map((entry) => entry.toJson()).toList());
    await prefs.setString(_incomeKey, jsonString);
  }

  // Fungsi untuk menyimpan daftar entri pengeluaran
  static Future<void> saveExpenseEntries(List<AccountEntry> expenses) async {
    final prefs = await _getPrefs();
    final String jsonString = json.encode(expenses.map((entry) => entry.toJson()).toList());
    await prefs.setString(_expenseKey, jsonString);
  }

  // Fungsi untuk menambahkan entri pemasukan
  static Future<void> addIncomeEntry(AccountEntry entry) async {
    List<AccountEntry> incomes = await loadIncomeEntries();
    incomes.add(entry);
    await saveIncomeEntries(incomes);
  }

  // Fungsi untuk menambahkan entri pengeluaran
  static Future<void> addExpenseEntry(AccountEntry entry) async {
    List<AccountEntry> expenses = await loadExpenseEntries();
    expenses.add(entry);
    await saveExpenseEntries(expenses);
  }

  // Fungsi untuk mengedit entri pemasukan
  static Future<void> editIncomeEntry(AccountEntry updatedEntry) async {
    List<AccountEntry> incomes = await loadIncomeEntries();
    final index = incomes.indexWhere((entry) => entry.id == updatedEntry.id);
    if (index != -1) {
      incomes[index] = updatedEntry;
      await saveIncomeEntries(incomes);
    }
  }

  // Fungsi untuk mengedit entri pengeluaran
  static Future<void> editExpenseEntry(AccountEntry updatedEntry) async {
    List<AccountEntry> expenses = await loadExpenseEntries();
    final index = expenses.indexWhere((entry) => entry.id == updatedEntry.id);
    if (index != -1) {
      expenses[index] = updatedEntry;
      await saveExpenseEntries(expenses);
    }
  }

  // Fungsi untuk menghapus entri pemasukan
  static Future<void> deleteIncomeEntry(String entryId) async {
    List<AccountEntry> incomes = await loadIncomeEntries();
    incomes.removeWhere((entry) => entry.id == entryId);
    await saveIncomeEntries(incomes);
  }

  // Fungsi untuk menghapus entri pengeluaran
  static Future<void> deleteExpenseEntry(String entryId) async {
    List<AccountEntry> expenses = await loadExpenseEntries();
    expenses.removeWhere((entry) => entry.id == entryId);
    await saveExpenseEntries(expenses);
  }

  // Fungsi untuk mendapatkan semua entri (pemasukan dan pengeluaran) dalam periode tertentu
  static Future<List<AccountEntry>> getAllEntries({DateTime? startDate, DateTime? endDate}) async {
    final List<AccountEntry> incomes = await loadIncomeEntries();
    final List<AccountEntry> expenses = await loadExpenseEntries();
    
    final List<AccountEntry> filteredEntries = [];
    
    for (var entry in incomes) {
      if ((startDate == null || entry.date.isAfter(startDate.subtract(const Duration(days: 1)))) &&
          (endDate == null || entry.date.isBefore(endDate.add(const Duration(days: 1))))) {
        filteredEntries.add(entry);
      }
    }
    for (var entry in expenses) {
      if ((startDate == null || entry.date.isAfter(startDate.subtract(const Duration(days: 1)))) &&
          (endDate == null || entry.date.isBefore(endDate.add(const Duration(days: 1))))) {
        filteredEntries.add(entry);
      }
    }
    
    return filteredEntries;
  }

  // Fungsi untuk menghitung total pemasukan lain-lain dalam periode tertentu
  static Future<double> getTotalOtherIncome({DateTime? startDate, DateTime? endDate}) async {
    final List<AccountEntry> incomes = await loadIncomeEntries();
    double total = 0.0;
    for (var entry in incomes) {
      if ((startDate == null || entry.date.isAfter(startDate.subtract(const Duration(days: 1)))) &&
          (endDate == null || entry.date.isBefore(endDate.add(const Duration(days: 1))))) {
        total += entry.amount;
      }
    }
    return total;
  }

  // Fungsi untuk menghitung total pengeluaran dalam periode tertentu
  static Future<double> getTotalExpense({DateTime? startDate, DateTime? endDate}) async {
    final List<AccountEntry> expenses = await loadExpenseEntries();
    double total = 0.0;
    for (var entry in expenses) {
      if ((startDate == null || entry.date.isAfter(startDate.subtract(const Duration(days: 1)))) &&
          (endDate == null || entry.date.isBefore(endDate.add(const Duration(days: 1))))) {
        total += entry.amount;
      }
    }
    return total;
  }

  // Fungsi untuk menghitung total penjualan dari transaksi
  static Future<double> getTotalSalesFromTransactions({DateTime? startDate, DateTime? endDate}) async {
    final allTransactions = await TransactionService.loadTransactions();
    double totalSales = 0.0;
    for (var transaction in allTransactions) {
      if ((startDate == null || transaction.transactionDate.isAfter(startDate.subtract(const Duration(days: 1)))) &&
          (endDate == null || transaction.transactionDate.isBefore(endDate.add(const Duration(days: 1))))) {
        for (var item in transaction.items) {
          totalSales += (item.quantity * item.priceAtSale);
        }
      }
    }
    return totalSales;
  }

  // Fungsi untuk menghitung keuntungan bersih
  static Future<double> calculateProfit({DateTime? startDate, DateTime? endDate}) async {
    final double totalOtherIncome = await getTotalOtherIncome(startDate: startDate, endDate: endDate);
    final double totalSales = await getTotalSalesFromTransactions(startDate: startDate, endDate: endDate);
    final double totalExpense = await getTotalExpense(startDate: startDate, endDate: endDate);

    return (totalOtherIncome + totalSales) - totalExpense;
  }
}