import 'package:flutter/material.dart';
import 'visitor_registration_page.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);
const String kVisitorRegistrationUrl = String.fromEnvironment(
  'VISITOR_REG_URL',
  defaultValue: 'https://srimcaai.web.app/register',
);

class VisitorQRPage extends StatelessWidget {
  const VisitorQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("QR Registration"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code Image
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/visitor_qr.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: lightGrey,
                      child: const Icon(
                        Icons.qr_code,
                        size: 80,
                        color: accentBlue,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Scan QR to Register",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: navyBlue,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                "Scan this QR code with your phone camera to open the visitor registration page.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How it works:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: navyBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _instructionRow(Icons.qr_code_scanner, "1. Scan the QR code at college entrance"),
                    _instructionRow(Icons.edit, "2. Fill in your details (Name, Mobile, Purpose)"),
                    _instructionRow(Icons.check_circle, "3. Submit and get approval"),
                    _instructionRow(Icons.notifications, "4. Receive visit confirmation"),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Manual Registration Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: accentBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VisitorRegistrationPage()),
                    );
                  },
                  icon: const Icon(Icons.edit, color: accentBlue),
                  label: const Text("Register Manually", style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),

              // View Link Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("QR Code links to: $kVisitorRegistrationUrl")),
                    );
                  },
                  icon: const Icon(Icons.link, color: Colors.white),
                  label: const Text("View Registration Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instructionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
