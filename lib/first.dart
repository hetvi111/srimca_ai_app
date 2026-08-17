import 'package:flutter/material.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  // Navy Blue Theme Colors
  static const Color navyDark = Color(0xFF001F3F);
  static const Color navyMedium = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color lightIndigo = Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Institution Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 65,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Hero Robot Asset with glowing effect
                    Container(
                      height: isDesktop ? 250 : 210,
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

                    const SizedBox(height: 24),

                    // Main Title
                    const Text(
                      'SRIMCA AI ASSISTANT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    const Text(
                      'Artificial Intelligence with Moral Commitment and Attitude.\nYour smart companion for campus life, notices, and studies.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Highlights pill row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeaturePill(Icons.psychology_outlined, 'AI Assistant'),
                        _buildFeaturePill(Icons.campaign_outlined, 'Live Notices'),
                        _buildFeaturePill(Icons.menu_book_outlined, 'Materials'),
                        _buildFeaturePill(Icons.qr_code_2_rounded, 'Visitor Pass'),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Only Action: "Get Started" Button (redirects directly to Login)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: accentBlue.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64B5F6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
