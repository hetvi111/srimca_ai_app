import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'visitor_qr_page.dart';
import 'visitor_profile_page.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class VisitorHomePage extends StatefulWidget {
  final String? visitorId;
  final String? visitorName;
  
  const VisitorHomePage({super.key, this.visitorId, this.visitorName});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  int _currentIndex = 0;
  
  final List<Map<String, dynamic>> faqs = [
    {'question': 'What courses does SRIMCA offer?', 'answer': 'SRIMCA offers BCA, MCA , MBA courses in Computer Science.'},
    {'question': 'What are the college timings?', 'answer': 'College is open from 9:00 AM to 5:00 PM, Monday to Saturday.'},
    {'question': 'How can I get admission?', 'answer': 'You can apply online through our website or visit the admission office directly.'},
    {'question': 'What is the contact number?', 'answer': 'You can reach us at +91 1234567890 or email at info@srimca.edu'},
    {'question': 'Where is SRIMCA located?', 'answer': 'SRIMCA is located in Kalol, Gandhinagar district, Gujarat.'},
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VisitorProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [navyBlue, navyBlueLight],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "SRIMCA AI Assistant",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorQRPage()));
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Welcome Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.people, size: 60, color: accentBlue),
                    ),

                    const SizedBox(height: 20),

                    // Welcome Text
                    const Text(
                      "Welcome, Visitor! 👋",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navyBlue),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "SRIMCA AI Assistant",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Your smart college assistant.\nAsk questions about courses, departments, and more.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Info
                    Row(
                      children: [
                        _quickInfo(Icons.school, "Courses", "BCA, B.Sc"),
                        _quickInfo(Icons.access_time, "Timing", "9AM-5PM"),
                        _quickInfo(Icons.location_on, "Location", "Kalol"),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // QR Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: accentBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorQRPage())),
                        icon: const Icon(Icons.qr_code_scanner, color: accentBlue),
                        label: const Text("Scan QR Code", style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Questions & Answers
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Questions & Answers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
                    ),
                    const SizedBox(height: 12),

                    _buildFaqItem("What courses does SRIMCA offer?", "SRIMCA offers BCA, B.Sc (IT), B.Com, and M.Sc courses in Computer Science."),
                    _buildFaqItem("What are the college timings?", "College is open from 9:00 AM to 5:00 PM, Monday to Saturday."),
                    _buildFaqItem("How can I get admission?", "You can apply online through our website or visit the admission office directly."),
                    _buildFaqItem("What is the contact number?", "You can reach us at +91 1234567890 or email at info@srimca.edu"),
                    _buildFaqItem("Where is SRIMCA located?", "SRIMCA is located in Kalol, Gandhinagar district, Gujarat."),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: BottomNavigationBar(
                currentIndex: 0,
                onTap: _onNavTap,
                selectedItemColor: accentBlue,
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chat"),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _quickInfo(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: lightGrey, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: accentBlue, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navyBlue), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          iconColor: accentBlue,
          collapsedIconColor: accentBlue,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.help_outline, color: accentBlue, size: 20),
          ),
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: navyBlue)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
