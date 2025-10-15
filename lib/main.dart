import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoppingapp/screens/home/product_detail_screen.dart';
import 'package:shoppingapp/screens/login_screen.dart';
import 'package:shoppingapp/screens/main_screen_wrapper.dart';
import 'package:shoppingapp/screens/profile/order_detail_screen.dart';
import 'package:shoppingapp/screens/profile/order_screen.dart';
import 'package:shoppingapp/screens/register_screen.dart';
import 'package:shoppingapp/screens/splash_screen.dart';
import 'package:shoppingapp/services/cart_service.dart';
import 'package:shoppingapp/services/favorite_service.dart';
import 'package:shoppingapp/services/notification_service.dart';
import 'package:shoppingapp/services/order_status_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  tz.initializeTimeZones();

  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    _notificationService.setNavigationCallback((route, arguments) {
      navigatorKey.currentState?.pushNamed(
        route,
        arguments: arguments,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => CartService()),
        ChangeNotifierProvider(create: (context) => FavoriteService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Freshmart',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthGate(),
        routes: {
          '/register_screen': (context) => const RegisterScreen(),
          '/home_screen': (context) => const MainScreenWrapper(),
          '/login_screen': (context) => const LoginScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/order_detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            return OrderDetailScreen(orderId: args?['orderId']);
          },
          '/product_detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            final productId = args?['productId'] as String?;
            if (productId == null || productId.isEmpty) {
              return const MainScreenWrapper();
            }
            return ProductDetailScreen(productId: productId);
          },
        },
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final OrderStatusService _orderStatusService = OrderStatusService();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _orderStatusService.startStatusUpdater();
        NotificationService().initialize();
      } else {
        _orderStatusService.stopStatusUpdater();
        NotificationService().dispose();
      }
    });
  }

  @override
  void dispose() {
    _orderStatusService.stopStatusUpdater();
    NotificationService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Đang kiểm tra...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreenWrapper();
        }
        return const SplashScreen(isInitialCheck: false);
      },
    );
  }
}
