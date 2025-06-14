// lib/services/data_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/customer.dart'; // Jika Anda juga memiliki customer di sini
import '../models/transaction.dart' as app_transaction; // Jika Anda juga memiliki transaction di sini
import '../models/debt.dart'; // Jika Anda juga memiliki debt di sini

class DataManager {
  static const String _productsKey = 'products';
  static const String _customersKey = 'customers'; // Key untuk customer
  static const String _transactionsKey = 'transactions'; // Key untuk transaction
  static const String _debtsKey = 'debts'; // Key untuk debt

  // --- Product Methods ---
  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString(_productsKey);
    if (productsJson == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(productsJson);
    return jsonList.map((jsonItem) => Product.fromJson(jsonItem)).toList();
  }

  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_productsKey, jsonString);
  }

  // --- Customer Methods (contoh, jika belum ada) ---
  static Future<List<Customer>> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? customersJson = prefs.getString(_customersKey);
    if (customersJson == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(customersJson);
    return jsonList.map((jsonItem) => Customer.fromJson(jsonItem)).toList();
  }

  static Future<void> saveCustomers(List<Customer> customers) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(customers.map((c) => c.toJson()).toList());
    await prefs.setString(_customersKey, jsonString);
  }

  // --- Transaction Methods (contoh, jika belum ada) ---
  static Future<List<app_transaction.Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString(_transactionsKey);
    if (transactionsJson == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(transactionsJson);
    return jsonList.map((jsonItem) => app_transaction.Transaction.fromJson(jsonItem)).toList();
  }

  static Future<void> saveTransactions(List<app_transaction.Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_transactionsKey, jsonString);
  }

  // --- Debt Methods (contoh, jika belum ada) ---
  static Future<List<Debt>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? debtsJson = prefs.getString(_debtsKey);
    if (debtsJson == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(debtsJson);
    return jsonList.map((jsonItem) => Debt.fromJson(jsonItem)).toList();
  }

  static Future<void> saveDebts(List<Debt> debts) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(debts.map((d) => d.toJson()).toList());
    await prefs.setString(_debtsKey, jsonString);
  }
}