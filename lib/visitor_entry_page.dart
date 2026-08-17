import 'package:flutter/material.dart';
import 'package:srimca_ai/VisitorHomePage.dart';

// Theme Colors
const Color primaryNavy = Color(0xFF001F3F);
const Color secondaryNavy = Color(0xFF0B2545);
const Color accentBlue = Color(0xFF1E88E5);
const Color softBlue = Color(0xFFE3F2FD);
const Color textDark = Color(0xFF1A1A1A);
const Color textMuted = Color(0xFF666666);

class VisitorEntryPage extends StatelessWidget {
  const VisitorEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20 : 36,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 36,
                    vertical: 36,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // College Logo & Mascot Header
                      Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.school_rounded,
                            size: 48,
                            color: primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Badge: Ask anything about SRIMCA
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 16,
                              color: accentBlue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Ask anything about SRIMCA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title: Welcome to SRIMCA AI Assistant
                      const Text(
                        'Welcome to SRIMCA\nAI Assistant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Brief Description
                      const Text(
                        'Your smart college companion for Shrimad Rajchandra Institute. Discover courses, admission guidelines, campus facilities, and get instant AI assistance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Primary Button: Get Started (Redirects to Register)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/register',
                            arguments: {'preselectRole': 'visitor'},
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: accentBlue.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Secondary Button: Login (If already registered)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: {'preselectRole': 'visitor'},
                          ),
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text(
                            'Already registered? Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryNavy,
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Continue as Guest Option
                      TextButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VisitorHomePage(
                              token: 'guest',
                              userId: 'guest',
                              userName: 'Guest Visitor',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.explore_outlined, size: 18, color: textMuted),
                        label: const Text(
                          'Continue as Guest Visitor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Gate QR Code Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/visitor_qr.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 36,
                                    color: primaryNavy,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Campus Gate QR',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryNavy,
                                    ),
                                  ),
                                  Text(
                                    'Scan this QR code anytime at the campus entrance to access SRIMCA AI.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
