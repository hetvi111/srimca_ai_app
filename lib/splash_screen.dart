import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Navy Blue Theme Colors
  static const Color navyBlue = Color(0xFF001F3F);
  static const Color navyBlueLight = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color navyBlueLighter = Color(0xFF3949AB); // light indigo blue
  @override
  void initState() {
    super.initState();

    // Animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationController.forward();

    // Navigate based on saved login session after splash delay.
    Timer(const Duration(seconds: 3), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    // Handle Firebase email verification link (app opened from email)
    try {
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();
      if (uri != null && FirebaseService.isSignInWithEmailLink(uri.toString())) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('email_for_sign_in_link');
        if (email != null && email.isNotEmpty) {
          final result = await FirebaseService.signInWithEmailLink(
            email: email,
            link: uri.toString(),
          );
          if (result['success'] == true) {
            await prefs.remove('email_for_sign_in_link');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email verified successfully!')),
              );
            }
          }
        }
      }
    } catch (_) {}

    final isLoggedIn = await AuthService.isLoggedIn();
    final savedUser = await AuthService.getUser();

    if (isLoggedIn && savedUser != null) {
      final role = (savedUser['role'] ?? '').toString().toLowerCase();
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
              'studentName': savedUser['name'] ?? 'Student',
              'semester': savedUser['semester'] ?? 'N/A',
              'userId': savedUser['_id'] ?? '',
              'email': savedUser['email'] ?? '',
              'enrollmentNumber': savedUser['enrollment'] ?? '',
              'course': savedUser['department'] ?? '',
            },
          );
          return;
        case 'visitor':
          Navigator.pushReplacementNamed(context, '/visitor');
          return;
        default:
          // Unknown role: clear stale session and go to login flow.
          await AuthService.clearAuth();
          Navigator.pushReplacementNamed(context, '/login');
          return;
      }
    }

    Navigator.pushReplacementNamed(context, '/first');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyBlue,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF001F3F), // Dark Top
                  Color(0xFF1A237E), // Medium
                  Color(0xFF3949AB), // Light Bottom
                ],
              ),
            ),
          ),
          
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentBlue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentBlue.withOpacity(0.1),
              ),
            ),
          ),

          // Main Content - ensure safe area and centered layout
          SafeArea(
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Animated Robot Icon
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.0)
                          .animate(_animationController),
                      child: Container(
                        width: 220,
                        height: 280,
                        child: Image.asset(
                          'assets/images/i1.png', // ✅ no space
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'SRIMCA AI ASSISTANT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subtitle
                    const Text(
                      'Artificial Intelligence with Moral Commitment and Attitude',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Loading indicator
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ),

                    // Bottom Logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
