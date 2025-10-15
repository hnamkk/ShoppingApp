import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _orderSubscription;
  String? _fcmToken;
  bool _isInitialized = false;

  Function(String route, Map<String, dynamic>? arguments)? _onNavigate;

  bool get hasNavigationCallback => _onNavigate != null;

  void setNavigationCallback(
      Function(String route, Map<String, dynamic>? arguments) callback) {
    _onNavigate = callback;
    if (kDebugMode) {
      print('Navigation callback đã được đăng ký');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();
      await _initializeLocalNotifications();
      await _getFCMToken();
      _setupMessageHandlers();
      _listenToOrderStatusChanges();

      _isInitialized = true;

      if (kDebugMode) {
        print('Notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'order_channel',
        'Order Notifications',
        description: 'Notifications for order status updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'promotion_channel',
        'Promotion Notifications',
        description: 'Notifications for promotions and offers',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'reminder_channel',
        'Reminder Notifications',
        description: 'Reminder notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    ];

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (var channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {

    if (response.payload != null) {
      if (_onNavigate != null) {
        _handleNotificationNavigation(response.payload!);
      } else {
        if (kDebugMode) {
          print('⚠️ Navigation callback chưa được đăng ký!');
        }
      }
    }
  }

  void _handleNotificationNavigation(String payload) {
    try {
      final parts = payload.split(':');
      final type = parts[0];
      final id = parts.length > 1 ? parts[1] : null;

      switch (type) {
        case 'order':
          if (id != null) {
            _onNavigate?.call('/order_detail', {'orderId': id});
          } else {
            _onNavigate?.call('/orders', null);
          }
          break;

        case 'cart':
          _onNavigate?.call('/cart', null);
          break;

        case 'promotion':
        case 'product':
          if (id != null) {
            _onNavigate?.call('/product_detail', {'productId': id});
          } else {
            _onNavigate?.call('/home', null);
          }
          break;

        default:
          _onNavigate?.call('/notifications', null);
      }

      if (kDebugMode) {
        print('Navigation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification navigation: $e');
      }
      _onNavigate?.call('/notifications', null);
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        if (kDebugMode) {
          print('FCM Token: $_fcmToken');
        }
        await _saveFCMToken(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveFCMToken(newToken);
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.toString(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message: ${message.notification?.title}');
      }
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Message opened app: ${message.data}');
      }
      _handleRemoteMessageNavigation(message);
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('Initial message: ${message.data}');
        }
        Future.delayed(const Duration(seconds: 1), () {
          _handleRemoteMessageNavigation(message);
        });
      }
    });
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    if (_onNavigate == null) {
      if (kDebugMode) {
        print('Navigation callback not registered yet');
      }
      return;
    }

    final data = message.data;
    final type = data['type'] as String?;
    final id = data['id'] as String? ?? data['orderId'] as String? ?? data['productId'] as String?;

    if (kDebugMode) {
      print('Remote navigation - type: $type, id: $id');
    }

    switch (type) {
      case 'order':
        if (id != null) {
          _onNavigate?.call('/order-detail', {'orderId': id});
        } else {
          _onNavigate?.call('/orders', null);
        }
        break;

      case 'cart':
        _onNavigate?.call('/cart', null);
        break;

      case 'promotion':
      case 'product':
        if (id != null) {
          _onNavigate?.call('/product-detail', {'productId': id});
        } else {
          _onNavigate?.call('/home_screen', null);
        }
        break;

      default:
        _onNavigate?.call('/notifications', null);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type = message.data['type'] as String? ?? 'general';
    String channelId;
    String channelName;

    switch (type) {
      case 'order':
        channelId = 'order_channel';
        channelName = 'Order Notifications';
        break;
      case 'promotion':
        channelId = 'promotion_channel';
        channelName = 'Promotion Notifications';
        break;
      case 'cart':
      case 'reminder':
        channelId = 'reminder_channel';
        channelName = 'Reminder Notifications';
        break;
      default:
        channelId = 'general_channel';
        channelName = 'General Notifications';
    }

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications from the app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String payload = type;
    final id = message.data['id'] as String? ??
        message.data['orderId'] as String? ??
        message.data['productId'] as String?;

    if (id != null) {
      payload = '$type:$id';
    }

    if (kDebugMode) {
      print('📱 Showing local notification with payload: $payload');
    }

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Thông báo',
      message.notification?.body ?? '',
      details,
      payload: payload,
    );
  }

  void _listenToOrderStatusChanges() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _orderSubscription?.cancel();
    _orderSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            _handleOrderStatusChange(data);
          }
        }
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('Error listening to order changes: $error');
      }
    });
  }

  void _handleOrderStatusChange(Map<String, dynamic> orderData) {
    final status = orderData['status'] as String?;
    final orderId = orderData['orderId'] as String?;

    if (status == null || orderId == null) return;

    String title = 'Cập nhật đơn hàng';
    String body = '';

    switch (status) {
      case 'pending':
        title = 'Đơn hàng đã được đặt';
        body = 'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang chờ xác nhận';
        break;
      case 'preparing':
        title = 'Đang chuẩn bị đơn hàng';
        body = 'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang được chuẩn bị';
        break;
      case 'delivering':
        title = 'Đang giao hàng';
        body = 'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đang được giao đến bạn';
        break;
      case 'delivered':
        title = 'Đã giao hàng';
        body = 'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được giao thành công';
        break;
      case 'cancelled':
        title = 'Đơn hàng đã hủy';
        body = 'Đơn hàng #${orderId.substring(0, 8).toUpperCase()} đã được hủy';
        break;
    }

    if (title.isNotEmpty && body.isNotEmpty) {
      showOrderNotification(title, body, orderId);
    }
  }

  Future<void> showOrderNotification(
      String title, String body, String orderId) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      orderId.hashCode,
      title,
      body,
      details,
      payload: 'order:$orderId',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<bool> hasNotificationPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> deleteFCMToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  void dispose() {
    _orderSubscription?.cancel();
  }

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
}