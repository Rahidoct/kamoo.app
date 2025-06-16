import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kamoo/auth/local_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  File? _profileImage;
  File? _storeLogo;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void showNotfikasi(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userMap = await LocalAuthService.getLoggedInUser();
      setState(() {
        _currentUser = userMap;
        if (_currentUser != null) {
          if (_currentUser!['imagePath'] != null) {
            _profileImage = File(_currentUser!['imagePath'] as String);
            if (!_profileImage!.existsSync()) {
              _profileImage = null;
            }
          } else {
            _profileImage = null;
          }
          if (_currentUser!['storeLogoPath'] != null) {
            _storeLogo = File(_currentUser!['storeLogoPath'] as String);
            if (!_storeLogo!.existsSync()) {
              _storeLogo = null;
            }
          } else {
            _storeLogo = null;
          }
        }
      });
    } catch (e) {
      showNotfikasi('Gagal memuat profil: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _currentUser != null) {
      final String? userEmail = _currentUser!['email'] as String?;
      if (userEmail != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await LocalAuthService.updateUserField(userEmail, 'imagePath', pickedFile.path);
        showNotfikasi('Yay! Foto profil berhasil diperbarui!');
      } else {
        showNotfikasi('Email user tidak ditemukan untuk menyimpan foto.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Tidak ada data profil ditemukan.', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          showNotfikasi('Silakan Login atau Daftar untuk melihat profil.');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF084FEA),
                        ),
                        child: const Text('Login / Daftar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF084FEA),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _currentUser!['nama'] ?? 'Nama belum diatur',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _currentUser!['email'] ?? 'Email belum diatur',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 15),
                              if (_currentUser!['toko'] != null) ...[
                                _buildProfileInfoItem(
                                  icon: Icons.store,
                                  title: 'Nama Toko',
                                  value: _currentUser!['toko'],
                                ),
                                const SizedBox(height: 15),
                              ],
                              if (_currentUser!['phoneNumber'] != null) ...[
                                _buildProfileInfoItem(
                                  icon: Icons.phone,
                                  title: 'Nomor Telepon',
                                  value: _currentUser!['phoneNumber'],
                                ),
                                const SizedBox(height: 15),
                              ],
                              if (_currentUser!['address'] != null) ...[
                                _buildProfileInfoItem(
                                  icon: Icons.location_on,
                                  title: 'Alamat Toko',
                                  value: _currentUser!['address'],
                                  isAddress: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileInfoItem({
    required IconData icon,
    required String title,
    required String value,
    bool isAddress = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF084FEA)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isAddress ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
