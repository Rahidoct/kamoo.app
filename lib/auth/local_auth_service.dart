import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';

class LocalAuthService {
  static const String _usersKey = 'users';
  static const String _loggedInUserKey = 'logged_in_user';

  /// Register user baru
  static Future<void> register(
    String username,
    String email,
    String password, // Ini adalah plain text password dari input
    {
    String? nama,
    String? toko,
    String? address,
    String? phoneNumber,
    String? imagePath,
    String? storeLogoPath,
    String? notes, // Tambahkan bidang baru untuk catatan
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userList = await _getUserList();

    // Cek apakah email sudah terdaftar
    final alreadyExists = userList.any((user) => user['email'] == email);
    if (alreadyExists) {
      return; // Tidak mendaftar jika email sudah ada
    }

    // Hashing password sebelum menyimpan
    final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    userList.add({
      'username': username,
      'email': email,
      'hashedPassword': hashedPassword, 
      'nama': nama ?? '',
      'toko': toko ?? '',
      'imagePath': imagePath,
      'storeLogoPath': storeLogoPath,
      'address': address ?? '',
      'phoneNumber': phoneNumber ?? '',
      'notes': notes ?? '', // Simpan catatan
    });

    await prefs.setString(_usersKey, jsonEncode(userList));
  }

  /// Login dan validasi berdasarkan email & password
  static Future<String> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final userList = await _getUserList();

    // Cari user berdasarkan email
    final user = userList.firstWhere(
      (u) => u['email'] == email,
      orElse: () => {},
    );

    if (user.isEmpty) {
      return 'wrong_email';
    }

    // Verifikasi password menggunakan BCrypt
    final String? storedHashedPassword = user['hashedPassword'];

    if (storedHashedPassword == null || !BCrypt.checkpw(password, storedHashedPassword)) {
      return 'wrong_password';
    }

    // Jika login berhasil, simpan user sebagai user yang sedang login
    await prefs.setString(_loggedInUserKey, jsonEncode(user));
    return 'success';
  }

  /// Ambil user yang sedang login
  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedInUserKey);
    if (userJson == null) {
      return null;
    }
    return Map<String, dynamic>.from(jsonDecode(userJson));
  }

  /// Update a specific field for the user identified by email.
  static Future<void> updateUserField(String email, String fieldName, dynamic newValue) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> userList = await _getUserList();

    // Temukan user di daftar user terdaftar
    int index = userList.indexWhere((user) => user['email'] == email);

    if (index != -1) {
      userList[index][fieldName] = newValue; // Perbarui bidang spesifik
      await prefs.setString(_usersKey, jsonEncode(userList));

      // Juga perbarui user yang sedang login jika itu adalah user yang sama
      Map<String, dynamic>? loggedInUser = await getLoggedInUser();
      if (loggedInUser != null && loggedInUser['email'] == email) {
        loggedInUser[fieldName] = newValue;
        await prefs.setString(_loggedInUserKey, jsonEncode(loggedInUser));
      }
    } else {
      // Opsi: tambahkan penanganan kesalahan jika user tidak ditemukan
      // print('User with email $email not found.');
    }
  }

  /// Update user profile fields (nama, toko, address, phoneNumber, imagePath, storeLogoPath, notes).
  static Future<void> updateUserProfile(String email, {
    String? nama,
    String? toko,
    String? address,
    String? phoneNumber,
    String? imagePath,
    String? storeLogoPath,
    String? notes, // Tambah parameter notes
  }) async {
    if (nama != null) await updateUserField(email, 'nama', nama);
    if (toko != null) await updateUserField(email, 'toko', toko);
    if (address != null) await updateUserField(email, 'address', address);
    if (phoneNumber != null) await updateUserField(email, 'phoneNumber', phoneNumber);
    if (imagePath != null) await updateUserField(email, 'imagePath', imagePath);
    if (storeLogoPath != null) await updateUserField(email, 'storeLogoPath', storeLogoPath);
    if (notes != null) await updateUserField(email, 'notes', notes); // Perbarui notes
  }

  /// Update user password after validating current password.
  static Future<String> updateUserPassword(String email, String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> userList = await _getUserList();

    int index = userList.indexWhere((user) => user['email'] == email);

    if (index == -1) {
      return 'user_not_found';
    }

    final user = userList[index];
    final String? storedHashedPassword = user['hashedPassword'];

    // Validate current password
    if (storedHashedPassword == null || !BCrypt.checkpw(currentPassword, storedHashedPassword)) {
      return 'wrong_current_password';
    }

    // Hash new password
    final String newHashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    // Update password in the user list
    userList[index]['hashedPassword'] = newHashedPassword;
    await prefs.setString(_usersKey, jsonEncode(userList));

    // Also update the logged-in user's password if it's the same user
    Map<String, dynamic>? loggedInUser = await getLoggedInUser();
    if (loggedInUser != null && loggedInUser['email'] == email) {
      loggedInUser['hashedPassword'] = newHashedPassword;
      await prefs.setString(_loggedInUserKey, jsonEncode(loggedInUser));
    }

    return 'success';
  }

  // --- Metode helper untuk mengambil properti user yang sedang login ---
  static Future<String?> getUsername() async {
    final user = await getLoggedInUser();
    return user?['username'] as String?;
  }

  static Future<String?> getNama() async {
    final user = await getLoggedInUser();
    return user?['nama'] as String?;
  }

  static Future<String?> getToko() async {
    final user = await getLoggedInUser();
    return user?['toko'] as String?;
  }

  static Future<String?> getEmail() async {
    final user = await getLoggedInUser();
    return user?['email'] as String?;
  }

  static Future<String?> getImagePath() async {
    final user = await getLoggedInUser();
    return user?['imagePath'] as String?;
  }

  static Future<String?> getStoreLogoPath() async {
    final user = await getLoggedInUser();
    return user?['storeLogoPath'] as String?;
  }

  static Future<String?> getAddress() async {
    final user = await getLoggedInUser();
    return user?['address'] as String?;
  }

  static Future<String?> getPhoneNumber() async {
    final user = await getLoggedInUser();
    return user?['phoneNumber'] as String?;
  }

  // Tambahkan getter baru untuk catatan
  static Future<String?> getNotes() async {
    final user = await getLoggedInUser();
    return user?['notes'] as String?;
  }

  /// Logout user yang sedang login
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserKey);
  }

  /// Helper: Ambil semua user yang terdaftar
  static Future<List<Map<String, dynamic>>> _getUserList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_usersKey);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}