import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _statusTimer;

  // Thời gian cho mỗi trạng thái (phút)
  static const int pendingToPreparing = 5; // 5 phút
  static const int preparingToDelivering = 10; // 10 phút
  static const int deliveringToDelivered = 9; // 9 phút (tổng 24h)

  void startStatusUpdater() {
    // Chạy mỗi phút để kiểm tra và cập nhật trạng thái
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateOrderStatuses();
    });

    // Chạy ngay lập tức khi khởi động
    _updateOrderStatuses();
  }

  void stopStatusUpdater() {
    _statusTimer?.cancel();
  }

  Future<void> _updateOrderStatuses() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final hour = now.hour;

      // Lấy tất cả đơn hàng đang xử lý của user
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status',
          whereIn: ['pending', 'preparing', 'delivering']).get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final minutesSinceCreated = now.difference(createdAt).inMinutes;

        String? newStatus;

        switch (status) {
          case 'pending':
          // Sau 5 phút chuyển sang preparing
            if (minutesSinceCreated >= pendingToPreparing) {
              newStatus = 'preparing';
            }
            break;

          case 'preparing':
          // Sau 15 phút (5 + 10) chuyển sang delivering
            if (minutesSinceCreated >= pendingToPreparing + preparingToDelivering) {
              newStatus = 'delivering';
            }
            break;

          case 'delivering':
          // Sau 24 phút (5 + 10 + 9) chuyển sang delivered
          // Nhưng chỉ giao từ 8h đến 18h
            const totalMinutes = pendingToPreparing + preparingToDelivering + deliveringToDelivered;

            if (minutesSinceCreated >= totalMinutes) {
              // Kiểm tra giờ giao hàng (8h - 18h)
              if (hour >= 8 && hour < 18) {
                newStatus = 'delivered';
              }
              // Nếu ngoài giờ giao hàng, giữ nguyên trạng thái delivering
              // và sẽ tự động chuyển sang delivered khi đến giờ
            }
            break;
        }

        if (newStatus != null) {
          await _firestore.collection('orders').doc(doc.id).update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Log error nhưng không throw để không làm gián đoạn timer
      print('Lỗi khi cập nhật trạng thái đơn hàng: $e');
    }
  }

  // Method để force update ngay lập tức (dùng cho testing)
  Future<void> forceUpdateStatuses() async {
    await _updateOrderStatuses();
  }
}