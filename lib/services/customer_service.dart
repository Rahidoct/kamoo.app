// lib/services/customer_service.dart
import '../models/customer.dart';
import 'data_manager.dart'; // Pastikan DataManager ada dan berfungsi

class CustomerService {
  static Future<List<Customer>> getCustomers() async {
    // Memuat daftar pelanggan dari DataManager
    return await DataManager.loadCustomers();
  }

  static Future<Customer?> getCustomerById(String id) async {
    // Replace this with your actual data fetching logic
    List<Customer> customers = await getCustomers(); // Assuming you have this method
    try {
      return customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCustomers(List<Customer> customers) async {
    // Menyimpan daftar pelanggan ke DataManager
    await DataManager.saveCustomers(customers);
  }

  // Jika Anda perlu operasi CRUD lain, tambahkan di sini
  static Future<void> addCustomer(Customer customer) async {
    List<Customer> currentCustomers = await getCustomers();
    currentCustomers.add(customer);
    await saveCustomers(currentCustomers);
  }

  static Future<void> updateCustomer(Customer customer) async {
    List<Customer> currentCustomers = await getCustomers();
    int index = currentCustomers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      currentCustomers[index] = customer;
      await saveCustomers(currentCustomers);
    }
  }

  static Future<void> deleteCustomer(String customerId) async {
    List<Customer> currentCustomers = await getCustomers();
    currentCustomers.removeWhere((c) => c.id == customerId);
    await saveCustomers(currentCustomers);
  }
}