// file: address_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shoppingapp/models/address_model.dart';

class AddressFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy UID của người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // 1. LƯU/CẬP NHẬT Địa Chỉ lên Firestore
  Future<bool> saveAddress(Address address) async {
    final uid = currentUserId;
    if (uid == null) {
      print('Lỗi: Người dùng chưa đăng nhập.');
      return false;
    }

    try {
      // Đường dẫn: users/{uid}/addresses/{default_address}
      // Giả sử mỗi người dùng chỉ lưu một địa chỉ mặc định.
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc('default_address') // Dùng ID cố định để dễ quản lý địa chỉ chính
          .set(address.toJson());

      return true;
    } catch (e) {
      print('Firestore Error saving address: $e');
      return false;
    }
  }

  // 2. TẢI Địa Chỉ từ Firestore
  Future<Address?> getAddress() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc('default_address')
          .get();

      if (docSnapshot.exists) {
        // Sử dụng Address.fromJson để chuyển đổi Map thành đối tượng Address
        return Address.fromJson(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      print('Firestore Error getting address: $e');
      return null;
    }
  }
}