import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoppingapp/screens/login_screen.dart';
import 'package:shoppingapp/screens/main_screen.dart';
import 'package:shoppingapp/screens/register_screen.dart';
import 'package:shoppingapp/screens/splash_screen.dart';
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

// ✅ FIXED: AuthGate với logic rõ ràng hơn
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Đang kiểm tra auth state - hiển thị loading đơn giản
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

        // 2. Đã đăng nhập - vào app ngay
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreenWrapper();
        }

        // 3. Chưa đăng nhập - hiển thị SplashScreen với animation đầy đủ
        return const SplashScreen(isInitialCheck: false);
      },
    );
  }
}