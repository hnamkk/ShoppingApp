import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/notification_helper.dart';
import '../services/notification_service.dart';

class OrderStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _statusTimer;

  static const int pendingToPreparing = 5;
  static const int preparingToDelivering = 10;
  static const int deliveringToDelivered = 9;

  void startStatusUpdater() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateOrderStatuses();
    });

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
        final orderId = data['orderId'] as String? ?? doc.id;

        String? newStatus;

        switch (status) {
          case 'pending':
            if (minutesSinceCreated >= pendingToPreparing) {
              newStatus = 'preparing';
            }
            break;

          case 'preparing':
            if (minutesSinceCreated >=
                pendingToPreparing + preparingToDelivering) {
              newStatus = 'delivering';
            }
            break;

          case 'delivering':
            const totalMinutes = pendingToPreparing +
                preparingToDelivering +
                deliveringToDelivered;

            if (minutesSinceCreated >= totalMinutes) {
              if (hour >= 8 && hour < 18) {
                newStatus = 'delivered';
              }
            }
            break;
        }

        if (newStatus != null) {
          await _firestore.collection('orders').doc(doc.id).update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          await _sendStatusChangeNotification(orderId, newStatus, userId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi cập nhật trạng thái đơn hàng: $e');
      }
    }
  }

  Future<void> _sendStatusChangeNotification(
      String orderId, String newStatus, String userId) async {
    try {
      await NotificationHelper.sendOrderStatusNotification(
        orderId,
        newStatus,
        userId: userId,
      );

      final prefs = await SharedPreferences.getInstance();
      final notificationEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      if (!notificationEnabled) {
        return;
      }

      final notificationService = NotificationService();
      String title = '';
      String body = '';

      switch (newStatus) {
        case 'preparing':
          title = 'Đang chuẩn bị đơn hàng';
          body =
              'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang được chuẩn bị';
          break;
        case 'delivering':
          title = 'Đang giao hàng';
          body =
              'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang trên đường giao đến bạn';
          break;
        case 'delivered':
          title = 'Đã giao hàng';
          body =
              'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được giao thành công!';
          break;
        case 'cancelled':
          title = 'Đơn hàng đã hủy';
          body =
              'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được hủy';
          break;
      }

      if (title.isNotEmpty) {
        await notificationService.showOrderNotification(title, body, orderId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi gửi notification: $e');
      }
    }
  }

  Future<void> forceUpdateStatuses() async {
    await _updateOrderStatuses();
  }
}
