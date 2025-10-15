import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart' as models;
import '../services/notification_service.dart';
import '../widgets/notification_helper.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createOrder(models.Order order) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final productDocs = <String, DocumentSnapshot>{};

        for (var item in order.items) {
          final productRef =
          _firestore.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);
          productDocs[item.productId] = productDoc;
        }

        for (var item in order.items) {
          final productDoc = productDocs[item.productId]!;
          if (!productDoc.exists) {
            throw Exception('Sản phẩm ${item.name} không tồn tại');
          }

          final data = productDoc.data() as Map<String, dynamic>;
          final currentStock = data['stock'] ?? 0;

          if (currentStock < item.quantity) {
            throw Exception(
                'Sản phẩm ${item.name} không đủ hàng. Còn lại: $currentStock');
          }
        }

        for (var item in order.items) {
          final productDoc = productDocs[item.productId]!;
          final data = productDoc.data() as Map<String, dynamic>;
          final currentStock = data['stock'] ?? 0;
          final currentSold = data['sold'] ?? 0;

          final productRef =
          _firestore.collection('products').doc(item.productId);
          transaction.update(productRef, {
            'stock': currentStock - item.quantity,
            'sold': currentSold + item.quantity,
          });
        }

        final orderRef = _firestore.collection('orders').doc();
        transaction.set(orderRef, order.toMap());

        return orderRef.id;
      });
    } catch (e) {
      throw Exception('Lỗi khi tạo đơn hàng: $e');
    }
  }

  Future<bool> _isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      String? userId;

      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final orderDoc = await transaction.get(orderRef);

        if (!orderDoc.exists) {
          throw Exception('Đơn hàng không tồn tại');
        }

        final orderData = orderDoc.data()!;
        final currentStatus = orderData['status'] ?? 'pending';

        userId = orderData['userId'] as String?;

        if (currentStatus != 'pending' && currentStatus != 'preparing') {
          throw Exception('Không thể hủy đơn hàng ở trạng thái $currentStatus');
        }

        final items = (orderData['items'] as List<dynamic>?) ?? [];

        final productDocs = <String, DocumentSnapshot>{};
        for (var itemData in items) {
          final productId = itemData['productId'];
          final productRef = _firestore.collection('products').doc(productId);
          final productDoc = await transaction.get(productRef);
          productDocs[productId] = productDoc;
        }

        for (var itemData in items) {
          final productId = itemData['productId'];
          final quantity = itemData['quantity'] ?? 0;
          final productDoc = productDocs[productId];

          if (productDoc != null && productDoc.exists) {
            final data = productDoc.data() as Map<String, dynamic>;
            final currentStock = data['stock'] ?? 0;
            final currentSold = data['sold'] ?? 0;

            final productRef = _firestore.collection('products').doc(productId);
            transaction.update(productRef, {
              'stock': currentStock + quantity,
              'sold': currentSold - quantity >= 0 ? currentSold - quantity : 0,
            });
          }
        }

        transaction.update(orderRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      });

      if (userId != null) {
        await NotificationHelper.sendOrderStatusNotification(
          orderId,
          'cancelled',
          userId: userId,
        );
      }

      final notificationEnabled = await _isNotificationEnabled();
      if (notificationEnabled) {
        final notificationService = NotificationService();
        await notificationService.showOrderNotification(
          'Đơn hàng đã hủy',
          'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được hủy',
          orderId,
        );
      }
    } catch (e) {
      throw Exception('Lỗi khi hủy đơn hàng: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final userId = orderDoc.data()?['userId'] as String?;

      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (userId != null) {
        await NotificationHelper.sendOrderStatusNotification(
          orderId,
          status,
          userId: userId,
        );
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái: $e');
    }
  }

  Future<List<models.Order>> getUserOrders() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Người dùng chưa đăng nhập');

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => models.Order.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải đơn hàng: $e');
    }
  }

  Future<models.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      return models.Order.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Lỗi khi tải đơn hàng: $e');
    }
  }

  Stream<List<models.Order>> getUserOrdersStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => models.Order.fromMap(doc.id, doc.data()))
        .toList());
  }
}