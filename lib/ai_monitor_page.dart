import 'package:flutter/material.dart';
import 'ai_query_monitoring_page.dart';
import 'faculty_ai_assistant_page.dart';

class AiMonitorPage extends StatelessWidget {
  const AiMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("AI Monitor"),
        backgroundColor: const Color(0xFF1F4E8C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _card(
              context,
              icon: Icons.analytics,
              title: "AI Query Monitoring",
              subtitle: "View student AI questions & responses",
              page: const AiQueryMonitoringPage(),
            ),

            const SizedBox(height: 16),

            _card(
              context,
              icon: Icons.smart_toy,
              title: "Faculty AI Assistant",
              subtitle: "Ask AI academic or administrative queries",
              page: const FacultyAiAssistantPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required Widget page}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF1F4E8C)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }
}
