import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = (args != null && args['role'] != null) ? args['role'] as String : 'Student';
    final enrollment = args != null ? (args['enrollment'] as String? ?? '') : '';
    final staffId = args != null ? (args['staffId'] as String? ?? '') : '';

    String title = 'Welcome!';
    String subtitle = "Let's Have Fun with SAI";
    String details = 'Start a conversation with SAI right now.';

    switch (role) {
      case 'Admin':
        title = 'Welcome, Admin';
        subtitle = 'You have administrative access.';
        details = 'Manage users and system settings.';
        break;
      case 'Faculty':
        title = 'Welcome, Faculty';
        subtitle = 'Signed in with institutional access.';
        details = staffId.isNotEmpty ? 'Staff ID: $staffId' : 'Staff account';
        break;
      case 'Visitor':
        title = 'Welcome, Visitor';
        subtitle = 'Visitor access (QR-registered).';
        details = 'Limited access until approved.';
        break;
      default:
        // Student
        title = 'Welcome, Student';
        subtitle = 'Signed in with enrollment account.';
        details = enrollment.isNotEmpty ? 'Enrollment: $enrollment' : 'Student account';
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F9FF),
                Color(0xFFE3F2FD),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top app bar: logo + title + actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 24, color: Colors.black87),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                        ),
                        Image.asset('assets/images/SAI.png', width: 40, height: 40, fit: BoxFit.contain),
                        const SizedBox(width: 10),
                        const Text('SAI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble, size: 22, color: Color(0xFF1E88E5)),
                          onPressed: () {
                            // open chat/home
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 22, color: Colors.black54),
                          onPressed: () {
                            // placeholder: open settings
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open settings')));
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Spacer(),

                // Robot Image
                Image.asset(
                  'assets/images/i1.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // Welcome Text (role-specific)
                Text(
                '$title 👋',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                details,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 12,
                    shadowColor: const Color(0xFF1E88E5),
                  ),
                  onPressed: () {
                    if (role.toLowerCase() == 'faculty') {
                      Navigator.pushReplacementNamed(context, '/faculty');
                    } else if (role.toLowerCase() == 'admin') {
                      Navigator.pushReplacementNamed(context, '/admin');
                    } else if (role.toLowerCase() == 'student') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/student',
                        arguments: {
                          'studentName': 'Malav',
                          'semester': '5th Semester',
                        },
                      );
                    } else if (role.toLowerCase() == 'visitor') {
                      Navigator.pushReplacementNamed(context, '/visitor');
                    } else {
                      Navigator.pushReplacementNamed(context, '/home'); // fallback
                    }

                  },
                  child: const Text(
                    'Start Chat with SAI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
