import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _canSkip = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    // Controller cho hiệu ứng fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Cho phép skip sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _canSkip = true);
      }
    });

    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 9800));
    if (mounted) {
      _goToLogin();
    }
  }

  void _onAnimationComplete() {
    setState(() => _animationCompleted = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  void _goToLogin() async {
    if (!_fadeController.isAnimating && _fadeController.value == 0) {
      await _fadeController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/intro.json',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    repeat: false,
                    controller: _controller,
                    onLoaded: (composition) {
                      _controller.duration = composition.duration;
                      _controller.forward().then((_) {
                        _onAnimationComplete();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  // Tên app
                  const Text(
                    'Freshmart',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mua sắm thông minh',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_canSkip)
            Positioned(
              bottom: 40,
              right: 30,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _goToLogin,
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.skip_next,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}