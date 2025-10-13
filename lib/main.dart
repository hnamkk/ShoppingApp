import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoppingapp/screens/login_screen.dart';
import 'package:shoppingapp/screens/main_screen.dart';
import 'package:shoppingapp/screens/register_screen.dart';
import 'package:shoppingapp/screens/splash_screen.dart';
import 'package:shoppingapp/services/cart_service.dart';
import 'package:shoppingapp/services/favorite_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthGate(),
        routes: {
          '/register_screen': (context) => const RegisterScreen(),
          '/home_screen': (context) => const MainScreenWrapper(),
          '/login_screen': (context) => const LoginScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
