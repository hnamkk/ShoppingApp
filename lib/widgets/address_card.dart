import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../screens/profile/address_screen.dart';
import '../services/address_service.dart';

class AddressCard extends StatefulWidget {
  const AddressCard({super.key});

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  Address? currentAddress;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final address = await AddressFirestoreService().getAddress();
      setState(() {
        currentAddress = address;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Lỗi khi tải địa chỉ: $e');
    }
  }

  Future<void> _saveAddress(Address address) async {
    try {
      await AddressFirestoreService().saveAddress(address);
      setState(() {
        currentAddress = address;
      });
    } catch (e) {
      debugPrint('Lỗi khi lưu địa chỉ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
      return _buildEmptyAddress(context);
    }
    return _buildAddressCard(context);
  }

  Widget _buildEmptyAddress(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.location_on, color: Colors.green, size: 28),
        title: const Text(
          'Chọn địa chỉ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Vui lòng thiết lập địa chỉ giao hàng',
            style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Color(0xFF757575)),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddressScreen(address: Address.defaultAddress()),
            ),
          );
          if (result != null && result is Address) {
            await _saveAddress(result);
          }
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.location_on, color: Colors.green, size: 28),
        title: Text(
          currentAddress!.getShortAddress(),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            currentAddress!.getFullAddress(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Color(0xFF757575)),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddressScreen(address: currentAddress!)),
          );
          if (result != null && result is Address) {
            await _saveAddress(result);
          }
        },
      ),
    );
  }
}
