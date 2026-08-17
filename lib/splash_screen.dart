import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Navy Blue Theme Colors
  static const Color navyDark = Color(0xFF001F3F);
  static const Color navyMedium = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color lightIndigo = Color(0xFF3949AB);

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    _initializeAppFlow();
  }

  Future<void> _initializeAppFlow() async {
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final user = await AuthService.getUser();
        if (user != null && mounted) {
          final role = (user['role'] as String? ?? '').toLowerCase();

          if (role.isNotEmpty && !kIsWeb) {
            try {
              await PushNotificationService.subscribeToRoleTopics(role);
            } catch (e) {
              debugPrint('FCM topic subscription note: $e');
            }
          }

          if (!mounted) return;

          switch (role) {
            case 'admin':
              Navigator.pushReplacementNamed(context, '/admin');
              return;
            case 'faculty':
              Navigator.pushReplacementNamed(context, '/faculty');
              return;
            case 'student':
              Navigator.pushReplacementNamed(
                context,
                '/student',
                arguments: {
                  'studentName': user['name'] ?? 'Student',
                  'semester': user['semester'] ?? 'semester',
                  'userId': user['_id'] ?? '',
                  'email': user['email'] ?? '',
                  'enrollmentNumber': user['enrollment'] ?? user['enrollment_number'] ?? '',
                  'course': user['department'] ?? user['course'] ?? '',
                },
              );
              return;
            case 'visitor':
              Navigator.pushReplacementNamed(
                context,
                '/visitor',
                arguments: {
                  'userId': user['_id'] ?? '',
                  'token': 'visitor',
                  'userName': user['name'] ?? 'Visitor',
                },
              );
              return;
          }
        }
      }
    } catch (e) {
      debugPrint('Splash authentication error: $e');
    }

    if (mounted) {
      if (kIsWeb) {
        final fragment = Uri.base.fragment;
        if (fragment.contains('visitor-welcome') || fragment.contains('visitor-entry')) {
          Navigator.pushReplacementNamed(context, '/visitor-welcome');
          return;
        }
        if (fragment.contains('visitor')) {
          Navigator.pushReplacementNamed(context, '/visitor');
          return;
        }
      }
      Navigator.pushReplacementNamed(context, '/first');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              navyDark,
              navyMedium,
              lightIndigo,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Institution Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Animated Robot with scaling
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withValues(alpha: 0.35),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/i1.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.smart_toy_rounded,
                            size: 140,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // App Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'SRIMCA AI ASSISTANT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Artificial Intelligence with Moral Commitment and Attitude',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
