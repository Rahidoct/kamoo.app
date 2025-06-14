import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../auth/local_auth_service.dart' as auth;
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showLoginSnackBar(String title, String message, ContentType type) {
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
              inMaterialBanner: true,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showLoginSnackBar(
        'Eeits!',
        'Email dan password engga boleh kosong yah.!',
        ContentType.help,
      );
      return;
    }

    final status = await auth.LocalAuthService.login(email, password);

    if (status == 'success') {
      final nama = await auth.LocalAuthService.getNama();

      // Tampilkan notifikasi sukses login di tengah
      _showLoginSnackBar(
        'Login Berhasil',
        'Selamat datang kembali, ${nama ?? "Kamoo"}!',
        ContentType.success,
      );

      // Delay agar notifikasi bisa terbaca user
      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(nama: nama ?? 'User'),
        ),
      );
    } else if (status == 'wrong_email') {
      _showLoginSnackBar(
        'Email Salah',
        'Email salah atau tidak terdaftar, cek lagi yah!',
        ContentType.help,
      );
    } else if (status == 'wrong_password') {
      _showLoginSnackBar(
        'Password Salah',
        'Password kamu salah, coba lagi ya!',
        ContentType.help,
      );
    } else {
      _showLoginSnackBar(
        'Login Gagal',
        'Email atau password kamu salah, coba lagi ya!',
        ContentType.failure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mengganti Icon dan Text "Kamoo" dengan Image.asset logo
              Image.asset(
                'assets/logo/kamoo_logo.png', // Path ke logo Kamoo Anda
                height: 100, // Sesuaikan tinggi logo sesuai kebutuhan
                // Anda bisa menambahkan errorBuilder jika logo tidak ditemukan
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    Icon(Icons.point_of_sale, size: 72, color: Color(0xFF084FEA)),
                    const SizedBox(height: 16),
                    const Text("Kamoo",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Menambahkan teks "Silakan login untuk mulai transaksi"
              Text(
                "Silakan login untuk mulai transaksi",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF084FEA),
                ),
                textAlign: TextAlign.center, // Pusatkan teks
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  // --- START MODIFIKASI ---
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF084FEA), width: 2), // Warna biru saat fokus
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF084FEA), width: 1), // Warna biru saat tidak fokus
                  ),
                  // --- END MODIFIKASI ---
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  // --- START MODIFIKASI ---
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF084FEA), width: 2), // Warna biru saat fokus
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF084FEA), width: 1), // Warna biru saat tidak fokus
                  ),
                  // --- END MODIFIKASI ---
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Color(0xFF084FEA),
                  ),
                  onPressed: _login,
                  child: const Text("Login", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Daftar',
                          style: TextStyle(color: Color(0xFF084FEA)),
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
}