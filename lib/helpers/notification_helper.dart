import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? orderId,
    String? productId,
    String? promoCode,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return;

    await _firestore.collection('notifications').add({
      'userId': targetUserId,
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'productId': productId,
      'promoCode': promoCode,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      ...?additionalData,
    });
  }

  static Future<int> getUnreadCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  static Stream<int> getUnreadCountStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<void> cleanOldNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<void> sendOrderCreatedNotification(
      String orderId, double totalAmount,
      {String? userId}) async {
    await createNotification(
      title: 'Đơn hàng đã được tạo',
      message:
          'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} với tổng giá trị ${_formatCurrency(totalAmount)} đã được đặt thành công.',
      type: 'order',
      orderId: orderId,
      userId: userId,
    );
  }

  static Future<void> sendOrderStatusNotification(String orderId, String status,
      {String? userId}) async {
    String title = '';
    String message = '';

    switch (status) {
      case 'preparing':
        title = 'Đang chuẩn bị đơn hàng';
        message =
            'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang được chuẩn bị';
        break;
      case 'delivering':
        title = 'Đang giao hàng';
        message =
            'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang trên đường giao đến bạn';
        break;
      case 'delivered':
        title = 'Đã giao hàng';
        message =
            'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được giao thành công. Cảm ơn bạn đã mua hàng!';
        break;
      case 'cancelled':
        title = 'Đơn hàng đã hủy';
        message =
            'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được hủy';
        break;
    }

    if (title.isNotEmpty) {
      await createNotification(
        title: title,
        message: message,
        type: 'order',
        orderId: orderId,
        userId: userId,
      );
    }
  }

  static Future<void> sendPromotionNotification(String title, String message,
      {String? promoCode, String? productId, String? userId}) async {
    await createNotification(
      title: title,
      message: message,
      type: 'promotion',
      promoCode: promoCode,
      productId: productId,
      userId: userId,
    );
  }

  static Future<void> sendFlashSaleNotification(String message,
      {String? promoCode, String? userId}) async {
    await createNotification(
      title: '⚡ Flash Sale đang diễn ra!',
      message: message,
      type: 'promotion',
      promoCode: promoCode,
      userId: userId,
    );
  }

  static Future<void> sendCartReminderNotification(int itemCount,
      {String? userId}) async {
    await createNotification(
      title: 'Giỏ hàng đang chờ bạn',
      message:
          'Bạn có $itemCount sản phẩm trong giỏ hàng. Hoàn tất đơn hàng ngay để nhận ưu đãi!',
      type: 'cart',
      userId: userId,
    );
  }

  static Future<void> sendLowStockWarningNotification(
      String productName, String productId,
      {String? userId}) async {
    await createNotification(
      title: 'Sản phẩm sắp hết hàng!',
      message: '$productName trong giỏ hàng của bạn sắp hết. Đặt hàng ngay!',
      type: 'cart',
      productId: productId,
      userId: userId,
    );
  }

  static Future<void> sendProductBackInStockNotification(
      String productName, String productId,
      {String? userId}) async {
    await createNotification(
      title: 'Sản phẩm đã có hàng!',
      message: '$productName bạn quan tâm đã có hàng trở lại. Xem ngay!',
      type: 'product',
      productId: productId,
      userId: userId,
    );
  }

  static Future<void> sendNewProductNotification(
      String productName, String productId,
      {String? userId}) async {
    await createNotification(
      title: 'Sản phẩm mới',
      message: 'Khám phá sản phẩm mới: $productName',
      type: 'product',
      productId: productId,
      userId: userId,
    );
  }

  static Future<void> sendWelcomeNotification({String? userId}) async {
    await createNotification(
      title: 'Chào mừng bạn đến với ứng dụng!',
      message: 'Khám phá hàng ngàn sản phẩm chất lượng với giá tốt nhất.',
      type: 'general',
      userId: userId,
    );
  }

  static Future<void> sendSystemNotification(String title, String message,
      {String? userId}) async {
    await createNotification(
      title: title,
      message: message,
      type: 'general',
      userId: userId,
    );
  }

  static Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    String? promoCode,
    String? productId,
  }) async {
    final batch = _firestore.batch();

    for (var userId in userIds) {
      final docRef = _firestore.collection('notifications').doc();
      batch.set(docRef, {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'promoCode': promoCode,
        'productId': productId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    required String type,
    String? promoCode,
    String? productId,
  }) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

    if (userIds.isNotEmpty) {
      await sendBulkNotification(
        userIds: userIds,
        title: title,
        message: message,
        type: type,
        promoCode: promoCode,
        productId: productId,
      );
    }
  }

  static Future<Map<String, int>> getNotificationStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final stats = <String, int>{
      'total': snapshot.docs.length,
      'unread': 0,
      'order': 0,
      'promotion': 0,
      'delivery': 0,
      'cart': 0,
      'product': 0,
      'general': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['isRead'] == false) {
        stats['unread'] = (stats['unread'] ?? 0) + 1;
      }
      final type = data['type'] as String? ?? 'general';
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return stats;
  }

  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}₫';
  }
}

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Stream<int>? countStream;
  final int? count;

  const NotificationBadge({
    super.key,
    required this.child,
    this.countStream,
    this.count,
  }) : assert(countStream != null || count != null,
            'Either countStream or count must be provided');

  @override
  Widget build(BuildContext context) {
    if (countStream != null) {
      return StreamBuilder<int>(
        stream: countStream,
        initialData: 0,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return _buildBadge(count);
        },
      );
    } else {
      return _buildBadge(count!);
    }
  }

  Widget _buildBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
