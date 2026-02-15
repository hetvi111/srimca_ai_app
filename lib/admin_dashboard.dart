import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_management.dart';
import 'content_control_page.dart';
import 'ai_monitoring_page.dart';
import 'reports_analytics_page.dart';
import 'security_page.dart';

/// ================== MAIN DASHBOARD ==================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    UserManagementPage(),
    ContentControlPage(),
    AIMonitoringPage(),
    ReportsAnalyticsPage(),
    SecurityMaintenancePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Content"),
          BottomNavigationBarItem(icon: Icon(Icons.monitor), label: "Monitoring"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: "Security"),
        ],
      ),
    );
  }
}

/// ================== HOME PAGE ==================
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  // Sample notifications
  final List<String> notifications = const [
    "New faculty upload pending approval",
    "Low-confidence AI response detected",
    "Database backup completed",
    "System maintenance scheduled at 10 PM"
  ];

  // Function to show notifications with swipe-to-dismiss
void _showNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      // Use a stateful builder to manage dynamic removal
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Notifications",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Check if there are notifications
                if (notifications.isEmpty)
                  const Text("No notifications", style: TextStyle(color: Colors.grey)),
                ...notifications.map(
                  (note) {
                    final index = notifications.indexOf(note);
                    return Dismissible(
                      key: Key(note + index.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() {
                          notifications.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Notification removed")),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.notifications, color: Colors.blue),
                        title: Text(note),
                      ),
                    );
                  },
                ).toList(),
              ],
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,

      /// ===== TOP HEADER =====
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Admin",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Notification Bell
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: () => _showNotifications(context),
                        ),
                        // Small red dot for new notifications
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150?img=3",
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),

      /// ===== BODY =====
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome Back 👋",
                      style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(today,
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 10),
                  const Text(
                    "All systems running normally ✅",
                    style: TextStyle(
                        fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              "Quick System Overview",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 20),

            /// Stats Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width < 600 ? 2 : 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final items = [
                  {"title": "Total Users", "value": "885", "icon": Icons.people},
                  {"title": "Total Subjects", "value": "42", "icon": Icons.menu_book},
                  {"title": "Queries Today", "value": "45", "icon": Icons.question_answer},
                  {"title": "Knowledge Base", "value": "320 MB", "icon": Icons.storage},
                ];

                return StatCard(
                  title: items[index]["title"] as String,
                  value: items[index]["value"] as String,
                  icon: items[index]["icon"] as IconData,
                );
              },
            ),

            const SizedBox(height: 25),
            const Text(
              "Quick Actions",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                ActionButton(icon: Icons.person_add, label: "Add User"),
                ActionButton(icon: Icons.approval, label: "Approve Uploads"),
                ActionButton(icon: Icons.bar_chart, label: "View Reports"),
                ActionButton(icon: Icons.security, label: "Security Settings"),
                ActionButton(icon: Icons.monitor, label: "Monitor AI"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ================== STAT CARD ==================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1E88E5), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}

/// ================== ACTION BUTTON ==================
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
