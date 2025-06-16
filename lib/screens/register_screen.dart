import 'package:flutter/material.dart';
import '../auth/local_auth_service.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final namaController = TextEditingController();
  final tokoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  void _register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final nama = namaController.text.trim();
    final toko = tokoController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if ([username, email, nama, toko, password, confirmPassword].any((e) => e.isEmpty)) {
      _showRegisterSnackBar(
        'Formnya Belum Lengkap',
        'Semua kolom wajib diisi yah...',
        ContentType.help,
      );
      return;
    }

    if (!RegExp(r"^[\w-.]+@([\w-]+\.)+[\w]{2,4}").hasMatch(email)) {
      _showRegisterSnackBar(
        'Format Email Salah',
        'Emailnya engga sesuai format nih!',
        ContentType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      _showRegisterSnackBar(
        'Yah.! Passwordnya Beda.',
        'Passwordnya engga cocok, coba dicek lagi ya!',
        ContentType.failure,
      );
      return;
    }

    await LocalAuthService.register(
      username,
      email,
      password,
      nama: nama,
      toko: toko,
    );

    _showRegisterSnackBar(
      'Pendaftaran Berhasil 🎉',
      'Selamat! pendaftaran akun Kamoo berhasil.. Silakan login yah!',
      ContentType.success,
    );

    Navigator.pop(context);
  }

  void _showRegisterSnackBar(String title, String message, ContentType type) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: AwesomeSnackbarContent(
              title: title,
              message: message,
              contentType: type,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss setelah 3 detik
    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 72, color: Color(0xFF084FEA)),
              const SizedBox(height: 16),
              const Text(
                "Daftar Akun Kamoo",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF084FEA)),
              ),
              const SizedBox(height: 24),

              _buildInputField(controller: namaController, label: "Nama Lengkap"),
              const SizedBox(height: 16),

              _buildInputField(controller: tokoController, label: "Nama Toko"),
              const SizedBox(height: 16),

              _buildInputField(controller: usernameController, label: "Username"),
              const SizedBox(height: 16),

              _buildInputField(
                controller: emailController,
                label: "Email",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                passwordController,
                "Password",
                showPassword,
                () => setState(() => showPassword = !showPassword),
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                confirmPasswordController,
                "Konfirmasi Password",
                showConfirmPassword,
                () => setState(() => showConfirmPassword = !showConfirmPassword),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF084FEA),
                  ),
                  child: const Text("DAFTAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: 'Sudah punya akun? ',
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(color: Color(0xFF084FEA), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 79, 102, 150)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF084FEA), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromARGB(255, 79, 102, 150), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 79, 102, 150)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF084FEA), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromARGB(255, 79, 102, 150), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }

}