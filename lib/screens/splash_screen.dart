import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final bool isInitialCheck;

  const SplashScreen({Key? key, this.isInitialCheck = false}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  void _goToLoginScreen() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login_screen');
    }
  }

  void _onAnimationComplete() {
    if (!mounted) return;

    setState(() => _animationCompleted = true);

    if (!widget.isInitialCheck) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fadeController.forward().then((_) {
            _goToLoginScreen();
          });
        }
      });
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
    bool showSkipButton = !widget.isInitialCheck && !_animationCompleted;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
          if (showSkipButton)
            Positioned(
              bottom: 40,
              right: 30,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () {
                    _controller.stop();
                    _fadeController.stop();
                    _goToLoginScreen();
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
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
