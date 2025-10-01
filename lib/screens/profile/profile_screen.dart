import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoppingapp/models/address_model.dart';
import 'package:shoppingapp/services/address_firestore_service.dart';
import '../../utils/constants.dart';
import 'address_screen.dart';
import 'package:shoppingapp/screens/login_screen.dart';
import 'package:shoppingapp/screens/main_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Address? currentAddress;
  bool isLoading = true;
  final AddressFirestoreService _addressService = AddressFirestoreService();

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() {
      isLoading = true;
    });

    final savedAddress = await _addressService.getAddress();

    setState(() {
      currentAddress = savedAddress;
      isLoading = false;
    });
  }

  Future<void> _saveAddress(Address address) async {
    final success = await _addressService.saveAddress(address);

    if (success) {
      setState(() {
        currentAddress = address;
      });
          } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể lưu địa chỉ. Vui lòng kiểm tra đăng nhập.')),
      );
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
                _buildAddressItem(context),

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

  Widget _buildAddressItem(BuildContext context) {
    if (isLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 8),
        elevation: 2,
        child: ListTile(
          leading: Icon(Icons.location_on, color: Colors.green),
          title: Text('Đang tải địa chỉ...'),
        ),
      );
    }

    if (currentAddress == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 28,
          ),
          title: const Text(
            'Chọn địa chỉ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Vui lòng thiết lập địa chỉ giao hàng',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Color(0xFF757575),
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddressScreen(
                  // Truyền Address.defaultAddress() (rỗng) cho form chỉnh sửa
                  address: Address.defaultAddress(),
                ),
              ),
            );

            if (result != null && result is Address) {
              await _saveAddress(result);
            }
          },
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(
          Icons.location_on,
          color: Colors.green,
          size: 28,
        ),
        title: Text(
          currentAddress!.getShortAddress(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            currentAddress!.getFullAddress(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddressScreen(
                address: currentAddress!,
              ),
            ),
          );

          if (result != null && result is Address) {
            await _saveAddress(result);
          }
        },
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
              onPressed: () {
                final appState = context.read<AppState>();
                appState.reset();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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