import 'package:flutter/material.dart';
import 'knowledge_page.dart';
import 'ai_monitor_page.dart';
import 'faculty_notice_management_page.dart';
import 'faculty_visitor_inquiry_page.dart';
import 'faculty_event_management_page.dart';
import 'faculty_notifications_page.dart';
import 'package:srimca_ai/faculty_profile_page.dart';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class FacultyHomePage extends StatefulWidget {
  final String name;
  final String staffId;
  final String department;
  final String email;
  final List<String> subjects;
  final int uploadedMaterials;
  final int studentQueries;
  final int subjectsCount;

  const FacultyHomePage({
    super.key,
    this.name = "Dr. Malav",
    this.staffId = "FAC001",
    this.department = "Computer Science",
    this.email = "malav@srimca.edu",
    this.subjects = const ['AI/ML', 'Data Science', 'Python'],
    this.uploadedMaterials = 12,
    this.studentQueries = 5,
    this.subjectsCount = 3,
  });

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {'total_materials': 0, 'total_queries': 0, 'total_subjects': 0};
  List<dynamic> notices = [];
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final statsData = await ApiService.getAdminStats();
      final noticesData = await ApiService.getNotices();
      final materialsData = await ApiService.getMaterials();
      
      setState(() {
        stats = {
          'total_materials': materialsData.length,
          'total_queries': 0,
          'total_subjects': widget.subjectsCount,
          'total_uploads': statsData['total_uploads'] ?? 0,
          'pending_uploads': statsData['pending_uploads'] ?? 0,
        };
        notices = noticesData;
        isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        stats = {
          'total_materials': widget.uploadedMaterials,
          'total_queries': widget.studentQueries,
          'total_subjects': widget.subjectsCount,
          'total_uploads': 0,
          'pending_uploads': 0,
        };
        notices = [];
        isLoadingStats = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      dashboardPage(),
      FacultyNoticeManagementPage(facultyId: widget.staffId, facultyName: widget.name),
      FacultyVisitorInquiryPage(facultyId: widget.staffId, facultyName: widget.name, department: widget.department),
      FacultyEventManagementPage(facultyId: widget.staffId, facultyName: widget.name),
      const FacultyNotificationsPage(),
      const AIAssistantPage(),
      FacultyProfilePage(userId: widget.staffId, staffId: widget.staffId),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: accentBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Notices"),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Visitors"),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "AI Monitor"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD PAGE =================
  Widget dashboardPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [navyBlue, navyBlueLight],
            ),
          ),
        ),
        title: const Text("Faculty Dashboard"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navyBlue, navyBlueLight],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: navyBlue, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, ${widget.name} 👋",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.department,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Stats Cards
              const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
              const SizedBox(height: 12),

              isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _overviewCard("Materials", stats['total_materials']?.toString() ?? '0', Icons.upload_file, accentBlue)),
                            const SizedBox(width: 12),
                            Expanded(child: _overviewCard("Queries", stats['total_queries']?.toString() ?? '0', Icons.chat_bubble_outline, Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _overviewCard("Subjects", stats['total_subjects']?.toString() ?? '0', Icons.book, Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: _overviewCard("Pending", stats['pending_uploads']?.toString() ?? '0', Icons.pending_actions, Colors.red)),
                          ],
                        ),
                      ],
                    ),

              const SizedBox(height: 30),

              // Quick Actions
              const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
              const SizedBox(height: 14),

              _actionCard(Icons.campaign, "Manage Notices", "Post and manage notices", () => _onItemTapped(1)),
              _actionCard(Icons.people, "Visitor Inquiries", "View and respond to visitors", () => _onItemTapped(2)),
              _actionCard(Icons.event, "Manage Events", "Create and manage college events", () => _onItemTapped(3)),
              _actionCard(Icons.psychology, "AI Monitoring", "Review AI responses", () => _onItemTapped(4)),

              const SizedBox(height: 30),

              // Recent Notices
              if (notices.isNotEmpty) ...[
                const Text("Recent Notices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
                const SizedBox(height: 12),
                ...notices.take(3).map((notice) => _noticeTile(notice['title'] ?? '', notice['created_at'] ?? '')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accentBlue.withOpacity(0.1),
                child: Icon(icon, color: accentBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            ],
          ),
        ),
      ),
    );
  }

  Widget _noticeTile(String title, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications, size: 18, color: accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// AI Assistant Page placeholder
class AIAssistantPage extends StatelessWidget {
  const AIAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("AI Monitoring"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 80, color: accentBlue),
            SizedBox(height: 16),
            Text("AI Response Monitoring", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text("Review AI-generated academic answers, report incorrect responses, and suggest improvements.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
