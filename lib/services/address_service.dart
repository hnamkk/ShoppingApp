import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shoppingapp/models/address_model.dart';

class AddressFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<bool> saveAddress(Address address) async {
    final uid = currentUserId;
    if (uid == null) {
      if (kDebugMode) {
        print('Lỗi: Người dùng chưa đăng nhập.');
      }
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc('default_address')
          .set(address.toJson());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firestore Error saving address: $e');
      }
      return false;
    }
  }

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
        return Address.fromJson(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Firestore Error getting address: $e');
      }
      return null;
    }
  }
}
