import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/firebase_service.dart';
import 'package:srimca_ai/push_notification_service.dart';
import 'package:flutter/foundation.dart';


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

    // Check visitor auth after animation
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkVisitorAuth();
      }
    });
  }

  Future<bool> _checkVisitorAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final savedUser = await AuthService.getUser();
      if (savedUser != null) {
        final role = (savedUser['role'] ?? '').toString().toLowerCase();
        if (role == 'visitor') {
          if (!kIsWeb) {
            try {
              await PushNotificationService.subscribeToRoleTopics(role);
            } catch (e) {
              debugPrint('Push subscription error: $e');
            }
          }
          if (mounted) Navigator.pushReplacementNamed(context, '/visitor');
          return true;
        }
      }
    }
    return false;
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
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        if (_animationController.value < 0.8) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          children: [
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                                  label: const Text(
                                    '🚀 QR Scan Entry',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 8,
                                  ),
                                  onPressed: () => Navigator.of(context).pushNamed('/qr-scan'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.login_rounded, color: Colors.white, size: 24),
                                  label: const Text(
                                    'Login / Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 70,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        );
                      },
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
