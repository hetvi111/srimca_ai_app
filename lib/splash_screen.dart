import 'package:flutter/material.dart';
import 'dart:async';

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

    // Navigate to first screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/first');
    });
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
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
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
