import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';

class VoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Voucher>> getActiveVouchers() async {
    try {
      final snapshot = await _firestore
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .get();

      final now = DateTime.now();

      final vouchers = snapshot.docs
          .map((doc) {
            try {
              return Voucher.fromMap(doc.id, doc.data());
            } catch (e) {
              print('Lỗi parse voucher ${doc.id}: $e');
              return null;
            }
          })
          .where((voucher) => voucher != null)
          .map((voucher) => voucher!)
          .where((voucher) => voucher.expiryDate.isAfter(now))
          .toList();

      print('Đã load ${vouchers.length} vouchers');
      return vouchers;
    } catch (e) {
      print('Lỗi khi tải voucher: $e');
      throw Exception('Lỗi khi tải voucher: $e');
    }
  }

  Future<Voucher?> applyVoucherByCode(String code, double orderAmount) async {
    try {
      final snapshot = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Mã voucher không tồn tại');
      }

      final voucher =
          Voucher.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());

      if (!voucher.isValid(orderAmount)) {
        throw Exception(
            voucher.getInvalidReason(orderAmount) ?? 'Voucher không hợp lệ');
      }

      return voucher;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementVoucherUsage(String voucherId) async {
    try {
      await _firestore.collection('vouchers').doc(voucherId).update({
        'usedCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Lỗi khi cập nhật voucher: $e');
      throw Exception('Lỗi khi cập nhật voucher: $e');
    }
  }

  Future<String> createVoucher(Voucher voucher) async {
    try {
      final docRef =
          await _firestore.collection('vouchers').add(voucher.toMap());
      print('Đã tạo voucher: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Lỗi khi tạo voucher: $e');
      throw Exception('Lỗi khi tạo voucher: $e');
    }
  }

  Stream<List<Voucher>> getVouchersStream() {
    return _firestore
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) {
            try {
              return Voucher.fromMap(doc.id, doc.data());
            } catch (e) {
              print('Lỗi parse voucher ${doc.id}: $e');
              return null;
            }
          })
          .where((voucher) => voucher != null)
          .map((voucher) => voucher!)
          .where((voucher) => voucher.expiryDate.isAfter(now))
          .toList();
    });
  }

  Future<bool> hasVouchers() async {
    try {
      final snapshot = await _firestore.collection('vouchers').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Lỗi kiểm tra vouchers: $e');
      return false;
    }
  }

  Future<List<Voucher>> getAllVouchers() async {
    try {
      final snapshot = await _firestore
          .collection('vouchers')
          .orderBy('expiryDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return Voucher.fromMap(doc.id, doc.data());
            } catch (e) {
              print('Lỗi parse voucher ${doc.id}: $e');
              return null;
            }
          })
          .where((voucher) => voucher != null)
          .map((voucher) => voucher!)
          .toList();
    } catch (e) {
      print('Lỗi khi tải tất cả voucher: $e');
      throw Exception('Lỗi khi tải voucher: $e');
    }
  }
}
