import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoppingapp/controllers/login_controller.dart';
import '../../main.dart';
import '../../utils/constants.dart';
import '../../widgets/address_card.dart';
import 'package:shoppingapp/screens/main_screen.dart';
import 'add_product_screen.dart';
import 'add_voucher_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idTokenResult = await user.getIdTokenResult();
      setState(() {
        isAdmin = idTokenResult.claims?['admin'] == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Địa chỉ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const AddressCard(),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileItem(
                    context,
                    Icons.add_shopping_cart,
                    'Thêm sản phẩm',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    context,
                    Icons.local_offer,
                    'Thêm voucher',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddVoucherScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Tài khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileItem(
                  context,
                  Icons.history,
                  AppStrings.orderHistory,
                  null,
                ),
                _buildProfileItem(
                  context,
                  Icons.favorite,
                  AppStrings.favorites,
                  null,
                ),
                _buildProfileItem(
                  context,
                  Icons.payment,
                  AppStrings.paymentMethods,
                  null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileItem(
                  context,
                  Icons.notifications,
                  AppStrings.notifications,
                  null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hỗ trợ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileItem(
                  context,
                  Icons.mail,
                  AppStrings.suggestion,
                  null,
                ),
                _buildProfileItem(
                  context,
                  Icons.info,
                  'Về ứng dụng',
                  null,
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFE57373)),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Color(0xFFE57373),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? 'Chưa có email';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green,
                width: 1,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/profile_selected.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userEmail,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF757575),
        ),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tính năng $title đang được phát triển'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Đăng xuất'),
          content: const Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
          actions: [
            TextButton(
              child: const Text(
                AppStrings.cancel,
                style: TextStyle(color: Color(0xFF757575)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final loginController = LoginController();
                await loginController.logout(context);
                final appState = context.read<AppState>();
                appState.reset();
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                  (route) => false,
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
