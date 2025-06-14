import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kamoo/auth/local_auth_service.dart'; // Pastikan path ini benar

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  File? _profileImage;
  File? _storeLogo; // New state for store logo

  // Controllers for Edit Profile Modal
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tokoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(); // New controller for address
  final TextEditingController _phoneNumberController = TextEditingController(); // New controller for phone number

  // Controllers for Edit Password Modal
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tokoController.dispose();
    _addressController.dispose(); // Dispose new controller
    _phoneNumberController.dispose(); // Dispose new controller
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
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
          // Set initial values for controllers
          _namaController.text = _currentUser!['nama'] ?? '';
          _tokoController.text = _currentUser!['toko'] ?? '';
          _addressController.text = _currentUser!['address'] ?? ''; // Set initial address
          _phoneNumberController.text = _currentUser!['phoneNumber'] ?? ''; // Set initial phone number

          if (_currentUser!['imagePath'] != null) {
            _profileImage = File(_currentUser!['imagePath'] as String);
            if (!_profileImage!.existsSync()) {
              _profileImage = null;
            }
          } else {
            _profileImage = null;
          }
          // Load store logo
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email user tidak ditemukan untuk menyimpan foto.')),
        );
      }
    } else {
      // No image picked or cancelled
    }
  }

  // New method for picking store logo
  Future<void> _pickStoreLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _currentUser != null) {
      final String? userEmail = _currentUser!['email'] as String?;
      if (userEmail != null) {
        setState(() {
          _storeLogo = File(pickedFile.path); // Update local state for modal
        });
        await LocalAuthService.updateUserField(userEmail, 'storeLogoPath', pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo toko berhasil diperbarui!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email user tidak ditemukan untuk menyimpan logo toko.')),
        );
      }
    } else {
      // No image picked or cancelled
    }
  }

  // --- Modals ---

  Future<void> _showEditProfileModal() async {
    if (_currentUser == null) return;

    // Set initial values for controllers
    _namaController.text = _currentUser!['nama'] ?? '';
    _tokoController.text = _currentUser!['toko'] ?? '';
    _addressController.text = _currentUser!['address'] ?? '';
    _phoneNumberController.text = _currentUser!['phoneNumber'] ?? '';
    // No need to set _storeLogo here, it's already managed by _loadUserProfile

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Profil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF084FEA),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Input Nama Lengkap
                    TextField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Input Nama Toko
                    TextField(
                      controller: _tokoController,
                      decoration: InputDecoration(
                        labelText: 'Nama Toko',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Input Alamat
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Alamat Toko',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 3, // Allow multiple lines for address
                    ),
                    const SizedBox(height: 15),
                    // Input Nomor Telepon
                    TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon Toko',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Bagian Upload Logo Toko
                    const Text(
                      'Logo Toko (Opsional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          // Gunakan setModalState untuk memperbarui _storeLogo di dalam modal
                          await _pickStoreLogo();
                          setModalState(() {
                            // Cek lagi setelah pickImage, mungkin file tidak ditemukan
                            if (_currentUser != null && _currentUser!['storeLogoPath'] != null) {
                                _storeLogo = File(_currentUser!['storeLogoPath'] as String);
                                if (!_storeLogo!.existsSync()) {
                                  _storeLogo = null;
                                }
                            } else {
                                _storeLogo = null;
                            }
                          });
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _storeLogo != null ? FileImage(_storeLogo!) : null,
                          child: _storeLogo == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
                                    const Text('Pilih Logo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentUser == null || _currentUser!['email'] == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tidak ada user terlogin untuk menyimpan.')),
                            );
                            return;
                          }

                          await LocalAuthService.updateUserProfile(
                            _currentUser!['email'] as String,
                            nama: _namaController.text,
                            toko: _tokoController.text,
                            address: _addressController.text, // Simpan alamat
                            phoneNumber: _phoneNumberController.text, // Simpan nomor telepon
                          );
                          await _loadUserProfile(); // Refresh data di layar utama
                          Navigator.pop(context); // Tutup modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF084FEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPasswordModal() async {
    if (_currentUser == null) return;

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmNewPasswordVisible = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ganti Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF084FEA),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: !isCurrentPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password Saat Ini',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            setModalState(() {
                              isCurrentPasswordVisible = !isCurrentPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.lock_open),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            setModalState(() {
                              isNewPasswordVisible = !isNewPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _confirmNewPasswordController,
                      obscureText: !isConfirmNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.check_circle),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            setModalState(() {
                              isConfirmNewPasswordVisible = !isConfirmNewPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentUser == null || _currentUser!['email'] == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tidak ada user terlogin untuk menyimpan.')),
                            );
                            return;
                          }

                          if (_newPasswordController.text.isEmpty || _confirmNewPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password baru tidak boleh kosong.')),
                            );
                            return;
                          }

                          if (_newPasswordController.text != _confirmNewPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Konfirmasi password tidak cocok.')),
                            );
                            return;
                          }

                          final String result = await LocalAuthService.updateUserPassword(
                            _currentUser!['email'] as String,
                            _currentPasswordController.text,
                            _newPasswordController.text,
                          );

                          if (result == 'success') {
                            await _loadUserProfile();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password berhasil diperbarui!')),
                            );
                          } else if (result == 'wrong_current_password') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password saat ini salah.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal memperbarui password: $result')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF084FEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Simpan Password Baru', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        centerTitle: true,
        backgroundColor: const Color(0xFF084FEA),
        foregroundColor: Colors.white,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Silakan Login atau Daftar untuk melihat profil.')),
                          );
                        },
                        child: const Text('Login / Daftar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: 1.8,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF084FEA), Color(0xFF4C8CFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Spacer(flex: 1),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.white,
                                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                                          child: _profileImage == null
                                              ? Icon(Icons.person, size: 50, color: Colors.grey[700])
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _currentUser!['username'] ?? 'Tidak Ada Username',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _currentUser!['email'] ?? 'Tidak Ada Email',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(flex: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: _buildCardInfoColumn(
                                            'Nama Lengkap', _currentUser!['nama'] ?? 'Aku tidak mengenalmu, kenalan yuk! cukup dengan edit profil.'),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildCardInfoColumn(
                                            'Nama Toko', _currentUser!['toko'] ?? 'Nama tokomu belum ada, yuk edit profil!'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Menampilkan info toko di luar kartu utama (Opsional, bisa juga di dalam kartu)
                      if (_currentUser != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Informasi Toko',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800]),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Logo Toko
                        Center(
                          child: _storeLogo != null
                              ? Image.file(
                                  _storeLogo!,
                                  height: 80, // Ukuran logo di tampilan profil
                                  width: 80,
                                  fit: BoxFit.contain,
                                )
                              : const Icon(Icons.storefront, size: 80, color: Color(0xFF084FEA)),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                            Icons.location_on, _currentUser!['address'] ?? 'Alamat Belum Disetel'),
                        _buildInfoRow(Icons.phone, _currentUser!['phoneNumber'] ?? 'Nomor Telepon Belum Disetel'),
                        const SizedBox(height: 20),
                      ],
                      

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showEditProfileModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF084FEA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Edit Profil',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showEditPasswordModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Ganti Password',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
      
    );
  }

  Widget _buildCardInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Helper widget to display new info rows
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Color(0xFF084FEA)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Color(0xFF084FEA)),
            ),
          ),
        ],
      ),
    );
  }
}