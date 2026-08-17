import 'package:flutter/material.dart';
import 'package:srimca_ai/visitor/visitor_home_screen.dart';

class VisitorWelcomeScreen extends StatelessWidget {
  const VisitorWelcomeScreen({super.key});

  static const Color brandIndigo = Color(0xFF2C3E9F);
  static const Color navyDark = Color(0xFF001F3F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF60A5FA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
              Color(0xFF93C5FD),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Top Section with Clouds & Robot Mascot
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cloud 1 (Top Left)
                              Positioned(
                                top: 20,
                                left: 16,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: Image.asset(
                                    'assets/images/cloud.png',
                                    width: isDesktop ? 160 : 110,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),

                              // Cloud 2 (Top Right)
                              Positioned(
                                top: 45,
                                right: 16,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: Image.asset(
                                    'assets/images/cloud.png',
                                    width: isDesktop ? 190 : 130,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),

                              // Robot Mascot
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Image.asset(
                                  'assets/images/i1.png',
                                  height: isDesktop ? 220 : 180,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    'assets/images/SAI.png',
                                    height: 180,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                      Icons.smart_toy_rounded,
                                      size: 120,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom White Card
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 550),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(36),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 24,
                                  offset: Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge: Ask anything about SRIMCA
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.smart_toy_rounded,
                                        size: 16,
                                        color: brandIndigo,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Ask anything about SRIMCA',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: brandIndigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Title: Welcome to SRIMCA AI Assistant
                                const Text(
                                  'Welcome to SRIMCA\nAI Assistant',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                    letterSpacing: -0.5,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Brief Description
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Your smart college companion for Shrimad Rajchandra Institute. Discover courses, admission guidelines, campus facilities, and get instant answers.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: textMuted,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Side-by-Side Action Buttons: [ LOGIN ] and [ REGISTER ]
                                Row(
                                  children: [
                                    // Login Button
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/login',
                                              arguments: {
                                                'preselectRole': 'visitor',
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.login_rounded,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: navyDark,
                                            side: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Register Button (Primary)
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/register',
                                              arguments: {
                                                'preselectRole': 'visitor',
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.person_add_alt_1_rounded,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: brandIndigo,
                                            foregroundColor: Colors.white,
                                            elevation: 3,
                                            shadowColor: const Color(0x662C3E9F),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // "Continue as Guest Visitor" Option
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const VisitorHomeScreen(
                                          token: 'guest',
                                          userId: 'guest',
                                          userName: 'Guest Visitor',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.explore_outlined,
                                    size: 18,
                                    color: textMuted,
                                  ),
                                  label: const Text(
                                    'Continue as Guest Visitor',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
