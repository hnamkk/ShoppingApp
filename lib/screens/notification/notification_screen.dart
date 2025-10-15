import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../profile/order_detail_screen.dart';
import '../profile/order_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ScrollController _scrollController = ScrollController();
  final List<QueryDocumentSnapshot> _notifications = [];
  final Map<String, bool> _readStatusOverride = {};

  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadInitialNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _notifications.clear();
      _readStatusOverride.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _notifications.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _notifications.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadInitialNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Thông báo'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(
                      Icons.done,
                      size: 20,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text('Đánh dấu đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_notifications.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: Colors.green,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return _buildLoadingIndicator();
          }

          final doc = _notifications[index];
          final data = doc.data() as Map<String, dynamic>;

          if (index == 0 || _shouldShowDateHeader(index)) {
            final dateHeader = _getDateHeader(data);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    dateHeader,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                _buildNotificationCard(doc.id, data),
              ],
            );
          }
          return _buildNotificationCard(doc.id, data);
        },
      ),
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    final currentData = _notifications[index].data() as Map<String, dynamic>;
    final previousData =
    _notifications[index - 1].data() as Map<String, dynamic>;

    final currentDate = (currentData['createdAt'] as Timestamp?)?.toDate();
    final previousDate = (previousData['createdAt'] as Timestamp?)?.toDate();

    if (currentDate == null || previousDate == null) return false;

    return _getDateHeader(currentData) != _getDateHeader(previousData);
  }

  String _getDateHeader(Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else if (difference < 7) {
      return DateFormat('EEEE', 'vi').format(createdAt);
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: Colors.green,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/notification.png',
            width: 100,
            height: 100,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String docId, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'general';
    final title = data['title'] as String? ?? 'Thông báo';
    final message = data['message'] as String? ?? '';
    final isRead = _readStatusOverride[docId] ?? (data['isRead'] as bool? ?? false);
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final orderId = data['orderId'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.green.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(docId, data),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(type, orderId, data, isRead),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isRead
                                        ? Colors.grey[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -4,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _deleteNotification(docId),
                  color: Colors.grey[400],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
      String type, String? orderId, Map<String, dynamic> data, bool isRead) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'order':
        final title = (data['title'] as String? ?? '').toLowerCase();
        final message = (data['message'] as String? ?? '').toLowerCase();

        if (title.contains('đã đặt') ||
            title.contains('đã được tạo') ||
            message.contains('chờ xác nhận')) {
          iconData = Icons.receipt_long;
          color = Colors.orange;
        } else if (title.contains('chuẩn bị') || message.contains('chuẩn bị')) {
          iconData = Icons.inventory_2_outlined;
          color = Colors.blue;
        } else if (title.contains('đang giao') ||
            message.contains('đang giao')) {
          iconData = Icons.local_shipping_outlined;
          color = Colors.purple;
        } else if (title.contains('đã giao') ||
            message.contains('giao thành công')) {
          iconData = Icons.check_circle_outline;
          color = Colors.green;
        } else if (title.contains('hủy') || message.contains('đã hủy')) {
          iconData = Icons.cancel_outlined;
          color = Colors.red;
        } else {
          iconData = Icons.shopping_bag_outlined;
          color = Colors.orange;
        }
        break;

      case 'promotion':
        iconData = Icons.local_offer_outlined;
        color = Colors.red;
        break;

      case 'delivery':
        iconData = Icons.local_shipping_outlined;
        color = Colors.blue;
        break;

      case 'cart':
      case 'reminder':
        iconData = Icons.shopping_cart_outlined;
        color = Colors.amber;
        break;

      default:
        iconData = Icons.notifications_outlined;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead ? color.withOpacity(0.1) : color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 22,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return DateFormat('HH:mm').format(dateTime);
    }
  }

  Future<void> _handleNotificationTap(
      String docId, Map<String, dynamic> data) async {
    final isRead = _readStatusOverride[docId] ?? (data['isRead'] as bool? ?? false);

    if (!isRead) {
      setState(() {
        _readStatusOverride[docId] = true;
      });

      _firestore.collection('notifications').doc(docId).update({
        'isRead': true,
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _readStatusOverride.remove(docId);
          });
        }
      });
    }

    if (!mounted) return;

    final type = data['type'] as String? ?? 'general';
    final orderId = data['orderId'] as String?;
    final promoCode = data['promoCode'] as String?;
    final productId = data['productId'] as String?;

    switch (type) {
      case 'order':
        if (orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrdersScreen(),
            ),
          );
        }
        break;

      case 'promotion':
        _showPromotionDialog(promoCode);
        break;

      case 'cart':
      case 'reminder':
        _showCartReminderDialog();
        break;

      case 'delivery':
        if (orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            ),
          );
        }
        break;

      default:
        break;
    }
  }

  void _showPromotionDialog(String? promoCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_offer, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text('Ưu đãi đặc biệt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (promoCode != null) ...[
              const Text('Mã khuyến mãi của bạn:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promoCode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Áp dụng ngay khi thanh toán để nhận ưu đãi!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mua sắm ngay'),
          ),
        ],
      ),
    );
  }

  void _showCartReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('Giỏ hàng đang chờ'),
          ],
        ),
        content: const Text(
          'Bạn có sản phẩm trong giỏ hàng. Hoàn tất đơn hàng ngay để không bỏ lỡ!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem giỏ hàng'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(String docId) async {
    await _firestore.collection('notifications').doc(docId).delete();

    setState(() {
      _notifications.removeWhere((doc) => doc.id == docId);
    });
  }

  Future<void> _markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final unreadDocs = _notifications.where((doc) {
      final docId = doc.id;
      final data = doc.data() as Map<String, dynamic>;
      final isRead = _readStatusOverride[docId] ?? (data['isRead'] as bool? ?? false);
      return !isRead;
    }).toList();

    if (unreadDocs.isEmpty) return;

    setState(() {
      for (var doc in unreadDocs) {
        _readStatusOverride[doc.id] = true;
      }
    });

    for (var doc in unreadDocs) {
      doc.reference.update({'isRead': true}).catchError((error) {
        debugPrint('Error updating notification: $error');
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa tất cả thông báo'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả thông báo? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _notifications.clear();
          _readStatusOverride.clear();
          _hasMore = false;
        });

        Navigator.pop(context);
      }
    } catch (error) {
      debugPrint('Error clearing notifications: $error');

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}