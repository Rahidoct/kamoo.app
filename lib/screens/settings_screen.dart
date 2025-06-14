import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/local_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmNewPasswordVisible = false;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final userMap = await LocalAuthService.getLoggedInUser();
    if (userMap != null) {
      setState(() {
        _currentUserEmail = userMap['email'] as String;
      });
    }
  }

  void _showCustomSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showChangePasswordModal() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    isCurrentPasswordVisible = false;
    isNewPasswordVisible = false;
    isConfirmNewPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ubah Kata Sandi',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      context,
                      controller: _currentPasswordController,
                      label: 'Password Saat Ini',
                      isVisible: isCurrentPasswordVisible,
                      icon: Icons.lock,
                      onToggleVisibility: () {
                        setModalState(() {
                          isCurrentPasswordVisible = !isCurrentPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordField(
                      context,
                      controller: _newPasswordController,
                      label: 'Password Baru',
                      isVisible: isNewPasswordVisible,
                      icon: Icons.lock_open,
                      onToggleVisibility: () {
                        setModalState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordField(
                      context,
                      controller: _confirmNewPasswordController,
                      label: 'Konfirmasi Password Baru',
                      isVisible: isConfirmNewPasswordVisible,
                      icon: Icons.check_circle,
                      onToggleVisibility: () {
                        setModalState(() {
                          isConfirmNewPasswordVisible = !isConfirmNewPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentPasswordController.text.isEmpty ||
                              _newPasswordController.text.isEmpty ||
                              _confirmNewPasswordController.text.isEmpty) {
                            _showCustomSnackBar(context, 'Semua bidang password harus diisi.', isError: true);
                            return;
                          }
                          if (_newPasswordController.text != _confirmNewPasswordController.text) {
                            _showCustomSnackBar(context, 'Password baru dan konfirmasi tidak cocok.', isError: true);
                            return;
                          }

                          if (_currentUserEmail != null) {
                            final String result = await LocalAuthService.updateUserPassword(
                              _currentUserEmail!,
                              _currentPasswordController.text,
                              _newPasswordController.text,
                            );

                            if (mounted) {
                              if (result == 'success') {
                                _showCustomSnackBar(context, 'Kata sandi berhasil diubah!');
                                Navigator.pop(context);
                              } else if (result == 'wrong_current_password') {
                                _showCustomSnackBar(context, 'Password saat ini salah.', isError: true);
                              } else if (result == 'user_not_found') {
                                _showCustomSnackBar(context, 'Pengguna tidak ditemukan.', isError: true);
                              } else {
                                _showCustomSnackBar(context, 'Gagal mengubah kata sandi.', isError: true);
                              }
                            }
                          } else {
                            _showCustomSnackBar(context, 'Tidak ada pengguna yang login.', isError: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Ubah Password',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required IconData icon,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: onToggleVisibility,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }

  void _showProfileSettingsModal() async {
    final userMap = await LocalAuthService.getLoggedInUser();
    final userNameController = TextEditingController(text: userMap?['nama'] ?? '');
    final userUsernameController = TextEditingController(text: userMap?['username'] ?? '');
    final userEmailController = TextEditingController(text: userMap?['email'] ?? '');
    File? userProfileImage = userMap?['imagePath'] != null && File(userMap!['imagePath'] as String).existsSync()
        ? File(userMap['imagePath'] as String)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              Future<void> pickImage() async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setModalState(() {
                    userProfileImage = File(pickedFile.path);
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pengaturan Profil',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: userProfileImage != null 
                                ? FileImage(userProfileImage!) 
                                : null,
                            child: userProfileImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey.shade600,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                onPressed: pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileTextField(
                      context,
                      controller: userNameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileTextField(
                      context,
                      controller: userUsernameController,
                      label: 'Username',
                      icon: Icons.tag,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileTextField(
                      context,
                      controller: userEmailController,
                      label: 'Email',
                      icon: Icons.email,
                      readOnly: true,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentUserEmail != null) {
                            await LocalAuthService.updateUserProfile(
                              _currentUserEmail!,
                              nama: userNameController.text,
                            );
                            if (userProfileImage != null) {
                              await LocalAuthService.updateUserField(_currentUserEmail!, 'imagePath', userProfileImage!.path);
                            }
                            if (mounted) {
                              _showCustomSnackBar(context, 'Profil berhasil diperbarui!');
                              Navigator.pop(context);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }

  void _showStoreSettingsModal() async {
    final userMap = await LocalAuthService.getLoggedInUser();
    final storeNameController = TextEditingController(text: userMap?['toko'] ?? '');
    final storeAddressController = TextEditingController(text: userMap?['address'] ?? '');
    final storePhoneNumberController = TextEditingController(text: userMap?['phoneNumber'] ?? '');
    File? storeLogo = userMap?['storeLogoPath'] != null && File(userMap!['storeLogoPath'] as String).existsSync()
        ? File(userMap['storeLogoPath'] as String)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              Future<void> pickImage() async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setModalState(() {
                    storeLogo = File(pickedFile.path);
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pengaturan Toko',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: storeLogo != null 
                                ? FileImage(storeLogo!) 
                                : null,
                            child: storeLogo == null
                                ? Icon(
                                    Icons.store,
                                    size: 50,
                                    color: Colors.grey.shade600,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                onPressed: pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileTextField(
                      context,
                      controller: storeNameController,
                      label: 'Nama Toko',
                      icon: Icons.store,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileTextField(
                      context,
                      controller: storeAddressController,
                      label: 'Alamat Toko',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileTextField(
                      context,
                      controller: storePhoneNumberController,
                      label: 'Nomor Telepon',
                      icon: Icons.phone,
                      readOnly: false,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentUserEmail != null) {
                            await LocalAuthService.updateUserProfile(
                              _currentUserEmail!,
                              toko: storeNameController.text,
                              address: storeAddressController.text,
                              phoneNumber: storePhoneNumberController.text,
                            );
                            if (storeLogo != null) {
                              await LocalAuthService.updateUserField(_currentUserEmail!, 'storeLogoPath', storeLogo!.path);
                            }
                            if (mounted) {
                              _showCustomSnackBar(context, 'Pengaturan toko berhasil disimpan!');
                              Navigator.pop(context);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.person,
                    title: 'Pengaturan Profil',
                    onTap: _showProfileSettingsModal,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.store,
                    title: 'Pengaturan Toko',
                    onTap: _showStoreSettingsModal,
                  ),
                ],
              ),
            ),
            
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.lock,
                    title: 'Ubah Kata Sandi',
                    onTap: _showChangePasswordModal,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.receipt,
                    title: 'Pengaturan Nota',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.phone_android,
                    title: 'Tampilan',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.sync_outlined,
                    title: 'Backup Data',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Kamoo App',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '© 2023 Kamoo Team',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.chevron_right, size: 20),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}