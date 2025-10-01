import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoppingapp/screens/login_screen.dart';
import 'package:shoppingapp/screens/main_screen.dart';
import 'package:shoppingapp/screens/profile/profile_screen.dart';
import 'package:shoppingapp/screens/register_screen.dart';
import 'package:shoppingapp/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Sử dụng Firebase options đã cấu hình
  );
  runApp(MyApp());
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
        home: const LoginScreen(),
        routes: {
          '/register_screen': (context) => const RegisterScreen(),
          '/home_screen': (context) => const MainScreenWrapper(),
          // Thêm các routes khác nếu cần
        },
      ),
    );
  }
}
