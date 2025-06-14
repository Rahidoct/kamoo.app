// lib/services/transaction_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart' as app_transaction; // Alias untuk menghindari konflik nama

class TransactionService {
  static const String _transactionsKey = 'transactions';

  static Future<List<app_transaction.Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString(_transactionsKey);
    if (transactionsJson == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(transactionsJson);
    return jsonList.map((jsonItem) => app_transaction.Transaction.fromJson(jsonItem)).toList();
  }

  // Metode baru: Menambahkan transaksi
  static Future<void> addTransaction(app_transaction.Transaction transaction) async {
    List<app_transaction.Transaction> currentTransactions = await getTransactions();
    currentTransactions.add(transaction);
    await saveTransactions(currentTransactions);
  }

  // Metode untuk menyimpan daftar transaksi
  static Future<void> saveTransactions(List<app_transaction.Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_transactionsKey, jsonString);
  }

  static Future<List<app_transaction.Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString('transactions');
    if (transactionsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(transactionsJson);
    return decoded
        .map((e) => app_transaction.Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  // Anda bisa menambahkan metode lain di sini (misalnya, getTransactionById, deleteTransaction)
}