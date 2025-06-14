import 'package:flutter/material.dart';
import '../auth/local_auth_service.dart';
import 'login_screen.dart';
// import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nama;

  // ignore: use_super_parameters
  const HomeScreen({Key? key, required this.nama}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _nama = '';
  String _toko = '';

  final List<String> _appBarTitles = [
    'DAFTAR BARANGKU',
    'DATA PELANGGANKU',
    'MENU TRANSAKSI',
    'RIWAYAT TRANSAKSI',
  ];

  final List<Widget> _widgetOptions = const [
    Center(child: Text('Product List')),
    Center(child: Text('Customer List')),
    Center(child: Text('Transaction')),
    Center(child: Text('Transaction History')),
    // const ProductListScreen(),
    // const CustomerListScreen(),
    // const TransactionScreen(),
    // const TransactionHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final toko = await LocalAuthService.getToko();
    final nama = await LocalAuthService.getNama();
    setState(() {
      _toko = toko ?? '';
      _nama = nama ?? 'Pengguna';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await LocalAuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF084FEA),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF084FEA),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Color(0xFF084FEA)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _toko,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Halo, $_nama!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil'),
              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => ProfileScreen(
              //         onProfileUpdated: (newNama, newToko) async {
              //           setState(() {
              //             _nama = newNama;
              //             _toko = newToko;
              //           });
              //         },
              //       ),
              //     ),
              //   );
              // },
            ),
            ListTile(
              leading: const Icon(Icons.join_right_outlined),
              title: const Text('Hutang'),
              // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Pembukuan'),
              // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountingScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Info Nota'),
              // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptInfoScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Bantuan'),
              // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
            Spacer(),
            // Footer di sidebar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kamoo App',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
      ),
      
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelanggan'),
              BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Transaksi'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
            ],
            currentIndex: _selectedIndex,
            backgroundColor: const Color(0xFF084FEA),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
