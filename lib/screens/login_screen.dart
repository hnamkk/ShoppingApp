import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginController _loginController = LoginController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = 'hnamkk1404@gmail.com';
    _passwordController.text = '1234567';
  }

  Future<void> _login() async {
    String? result = await _loginController.login(
        _usernameController.text, _passwordController.text, context);

    if (result != null) {
      if (result.length == 28) {
        Navigator.pushReplacementNamed(context, '/home_screen',
            arguments: result);
      }
    }
  }

  Future<String> _loginWithGoogle(BuildContext context) async {
    String? result = await _loginController.loginWithGoogle(context);

    if (result.isNotEmpty) {
      if (kDebugMode) {
        print("UID: $result");
      }
      if (result.length == 28) {
        Navigator.pushReplacementNamed(context, '/home_screen',
            arguments: result);
      }
    }
    return result ?? '';
  }

  Future<void> _resetPassword() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lấy lại mật khẩu'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Nhập email của bạn',
              labelStyle: const TextStyle(
                color: Colors.black,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(
                  color: Colors.green,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.green.shade600),
              child: const Text('Xác nhận'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Positioned(
          bottom: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Quên mật khẩu?'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register_screen');
                },
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.green.shade600),
                child: const Text('Đăng ký ngay?'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 150.0,
                height: 150.0,
                child: Image(
                  image: AssetImage('assets/images/logo.png'),
                ),
              ),
              const SizedBox(height: 50.0),
              SizedBox(
                width: 300.0,
                height: 50.0,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            const BorderSide(color: Colors.green, width: 1)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: 300.0,
                height: 50.0,
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: const TextStyle(
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: 300.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  child: const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: 300.0,
                height: 40.0,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _loginWithGoogle(context);
                  },
                  style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.green, width: 1),
                      foregroundColor: Colors.black),
                  icon: SvgPicture.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 24.0,
                    width: 24.0,
                  ),
                  label: const Text(
                    'Đăng nhập bằng Google',
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        )
      ],
    ));
  }
}
