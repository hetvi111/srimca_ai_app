import 'package:flutter/material.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/VisitorHomePage.dart';

// Theme colors
const Color navyBlue = Color(0xFF001F3F);
const Color accentBlue = Color(0xFF1E88E5);

class VisitorEntryPage extends StatelessWidget {
  const VisitorEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header + Logo
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 120),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Visitor!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Thanks for scanning the gate QR. Access AI Chat, profile, and more.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            // Action Buttons
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Login Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 28),
                        label: const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/login',
                          arguments: {'preselectRole': 'visitor'},
                        ),
                      ),
                    ),
                  ),
                  // Register Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, size: 28),
                        label: const Text(
                          'REGISTER',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: navyBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: {'preselectRole': 'visitor'},
                        ),
                      ),
                    ),
                  ),
                  // Guest Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.explore, size: 28),
                        label: const Text(
                          'CONTINUE AS GUEST',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VisitorHomePage(
                              token: 'guest',
                              userId: 'guest',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Image.asset('assets/images/visitor_qr.png', height: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

