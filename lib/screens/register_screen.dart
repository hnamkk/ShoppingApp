import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordAgainController =
      TextEditingController();
  final RegisterController _registerController = RegisterController();

  Future<void> _register() async {
    if (_passwordController.text != _passwordAgainController.text) {
      return;
    }
    String? result = await _registerController.register(
      _emailController.text,
      _passwordController.text,
    );

    if (result != null) {
      if (kDebugMode) {
        print("UID: $result");
      }
      if (result.length == 28) {
        Navigator.pushReplacementNamed(context, '/home_screen',
            arguments: result);
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    String? result = await _registerController.registerWithGoogle();

    if (result.isNotEmpty) {
      if (kDebugMode) {
        print("UID: $result");
      }
      if (result.length == 28) {
        Navigator.pushReplacementNamed(context, '/home_screen',
            arguments: result);
      }
    }
  }

  bool _isPasswordVisible = false;
  bool _isPasswordVisible2 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Center(
              child: Padding(
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
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
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
                      height: 50.0,
                      child: TextField(
                        controller: _passwordAgainController,
                        decoration: InputDecoration(
                          labelText: 'Nhập lại mật khẩu',
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
                              _isPasswordVisible2
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible2 = !_isPasswordVisible2;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible2,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: 300.0,
                      height: 40.0,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text('Đăng ký'),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: 300.0,
                      height: 40.0,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            side:
                                const BorderSide(color: Colors.green, width: 1),
                            foregroundColor: Colors.black),
                        onPressed: () async {
                          await _registerWithGoogle();
                        },
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
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
