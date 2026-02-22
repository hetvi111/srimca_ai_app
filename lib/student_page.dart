import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'student_profile_page.dart';
import 'student_notice_page.dart';
import 'student_notifications_page.dart';
import 'student_chat_history_page.dart';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class StudentHomePage extends StatefulWidget {
  final String studentName;
  final String semester;
  final String userId;
  final String email;
  final String? enrollmentNumber;
  final String? course;

  const StudentHomePage({
    super.key,
    this.studentName = "student",
    this.semester = "N/A",
    this.userId = "",
    this.email = "",
    this.enrollmentNumber,
    this.course,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {'total_notices': 0, 'total_assignments': 0, 'total_materials': 0};
  List<dynamic> notices = [];
  List<dynamic> assignments = [];
  List<dynamic> materials = [];
  bool isLoadingStats = true;
  bool isLoadingNotices = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['userId'] != null) {
      if (args['userId'] != widget.userId && widget.userId.isEmpty) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _loadDashboardData() async {
    String userId = widget.userId;
    if (userId.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        userId = args['userId'] as String? ?? '';
      }
    }
    
    try {
      final noticesData = await ApiService.getNotices();
      final assignmentsData = await ApiService.getAssignments();
      final materialsData = await ApiService.getMaterials();
      
      if (mounted) {
        setState(() {
          notices = noticesData;
          assignments = assignmentsData;
          materials = materialsData;
          stats = {
            'total_notices': noticesData.length,
            'total_assignments': assignmentsData.length,
            'total_materials': materialsData.length,
          };
          isLoadingStats = false;
          isLoadingNotices = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          notices = [
            {'title': 'Welcome to SRIMCA AI', 'content': 'Your AI assistant is ready to help!', 'created_at': '2024-02-20'},
            {'title': 'Exam Schedule', 'content': 'Mid-term exams starting next week', 'created_at': '2024-02-19'},
            {'title': 'New Assignment', 'content': 'AI Assignment submission deadline extended', 'created_at': '2024-02-18'},
          ];
          assignments = [
            {'title': 'AI Basics', 'description': 'Complete Chapter 1-3', 'due_date': '2024-02-20'},
            {'title': 'Machine Learning', 'description': 'Practice exercises', 'due_date': '2024-02-25'},
          ];
          materials = [
            {'title': 'Python Basics', 'subject': 'Computer Science'},
            {'title': 'AI Introduction', 'subject': 'AI/ML'},
          ];
          stats = {
            'total_notices': notices.length,
            'total_assignments': assignments.length,
            'total_materials': materials.length,
          };
          isLoadingStats = false;
          isLoadingNotices = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _homePageContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navyBlue, navyBlueLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: navyBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.waving_hand, color: Colors.white, size: 24),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.semester,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome, ${widget.studentName} 👋",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your AI assistant is ready to help!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Cards Row
            isLoadingStats
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _quickCard("Notices", stats['total_notices']?.toString() ?? '0', Colors.blue, Icons.notifications),
                      _quickCard("Assignments", stats['total_assignments']?.toString() ?? '0', Colors.orange, Icons.assignment),
                      _quickCard("Materials", stats['total_materials']?.toString() ?? '0', Colors.green, Icons.library_books),
                    ],
                  ),
            const SizedBox(height: 24),

            // Recent Notices Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Notices",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyBlue,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentNoticePage()),
                    );
                  },
                  child: const Text("View All", style: TextStyle(color: accentBlue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            isLoadingNotices
                ? const Center(child: CircularProgressIndicator())
                : notices.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No notices available"),
                        ),
                      )
                    : Column(
                        children: notices.take(3).map<Widget>((notice) {
                          final title = notice['title'] ?? 'Untitled';
                          final subtitle = notice['content'] ?? notice['description'] ?? '';
                          final date = notice['created_at'] ?? '';
                          return _noticeTile(title, subtitle, date);
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _quickCard(String title, String count, Color color, IconData icon) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeTile(String title, String subtitle, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications, color: accentBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: navyBlue,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: navyBlue,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navyBlue, navyBlueLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: navyBlue),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem("Home", "Dashboard", 0, icon: Icons.home),
          _drawerItem("SRIMCA AI Chat", "Chat with AI", 1, icon: Icons.chat_bubble),
          _drawerItem("Profile", "View Profile", 2, icon: Icons.person),
          const Divider(color: Colors.white24),
          _drawerItem("Notifications", "View Notifications", null, icon: Icons.notifications_active),
          _drawerItem("Chat History", "View Past Chats", null, icon: Icons.history),
          _drawerItem("Notices", "View Notices", null, icon: Icons.dashboard),
          const Divider(color: Colors.white24),
          _drawerItem("Logout", "Sign Out", null, icon: Icons.logout, isLogout: true),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, String subtitle, int? index, {IconData? icon, bool isLogout = false}) {
    return ListTile(
      leading: Icon(
        icon ?? Icons.circle,
        color: isLogout ? Colors.red[300] : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red[300] : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (index != null) {
          _onItemTapped(index);
        } else if (title == "Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentNotificationsPage(userId: widget.userId),
            ),
          );
        } else if (title == "Chat History") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentChatHistoryPage(userId: widget.userId),
            ),
          );
        } else if (title == "Notices") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentNoticePage()),
          );
        } else if (title == "Logout") {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentNotificationsPage(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homePageContent(),
          ChatScreen(userId: widget.userId),
          StudentProfilePage(
            userId: widget.userId,
            enrollmentNumber: widget.enrollmentNumber,
            course: widget.course,
            semester: widget.semester,
          ),
        ],
      ),
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
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: "AI Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
