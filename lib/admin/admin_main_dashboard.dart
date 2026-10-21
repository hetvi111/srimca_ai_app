import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/admin/admin_dashboard_view.dart';
import 'package:srimca_ai/admin/campus_navigation_management_view.dart';
import 'package:srimca_ai/admin/ai_knowledge_base_view.dart';
import 'package:srimca_ai/admin/notices_notifications_view.dart';
import 'package:srimca_ai/admin/user_management_view.dart';
import 'package:srimca_ai/admin/visitor_pass_approval_view.dart';
import 'package:srimca_ai/admin/reports_activity_logs_view.dart';

// Theme colors consistent with SAI Design System
class AppTheme {
  static const Color appBarColor = Color(0xFF001F3F); // Navy Blue
  static const Color drawerColor = Color(0xFF0A192F); // Deep Navy
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color buttonColor = Color(0xFF1E88E5); // Accent Blue
  static const Color textColor = Color(0xFF0F172A);
}

class NavigationItem {
  final IconData icon;
  final String title;
  final int index;
  final String description;

  const NavigationItem(this.icon, this.title, this.index, this.description);
}

/// ================== ADMIN MAIN DASHBOARD ==================
/// Replaces the legacy 9-feature dashboard with the 7 core modules:
/// 1. Dashboard (Live DB statistics, charts, recent activities & notices)
/// 2. Campus Navigation Management (Locations CRUD, map preview, AI sync)
/// 3. AI Knowledge Base (Official facts CRUD, unresolved queries resolution)
/// 4. Notices & Notifications (Draft/publish, target roles, push delivery)
/// 5. User Management (Roles, status, safe credentials, search/filters)
/// 6. Visitor Pass Approval (Pass review, approve/reject, secure QR token)
/// 7. Reports & Activity Logs (Module reports, CSV exports, audit trails)
class AdminMainDashboard extends StatefulWidget {
  const AdminMainDashboard({super.key});

  @override
  State<AdminMainDashboard> createState() => _AdminMainDashboardState();
}

class _AdminMainDashboardState extends State<AdminMainDashboard> {
  int _selectedIndex = 0;
  String _adminEmail = 'Administrator';
  Key _pageKey = UniqueKey();

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      Icons.dashboard_rounded,
      'Dashboard',
      0,
      'Live database metrics, statistics & recent activities',
    ),
    NavigationItem(
      Icons.explore_rounded,
      'Campus Navigation',
      1,
      'Manage locations, GPS coordinates & AI map navigation',
    ),
    NavigationItem(
      Icons.psychology_rounded,
      'AI Knowledge Base',
      2,
      'Official college facts, Q&A training & query resolution',
    ),
    NavigationItem(
      Icons.campaign_rounded,
      'Notices & Notifications',
      3,
      'Publish announcements & push notifications by role',
    ),
    NavigationItem(
      Icons.manage_accounts_rounded,
      'User Management',
      4,
      'Role access control, student & faculty accounts',
    ),
    NavigationItem(
      Icons.badge_rounded,
      'Visitor Pass Approval',
      5,
      'Review visitor applications & issue secure QR passes',
    ),
    NavigationItem(
      Icons.insights_rounded,
      'Reports & Activity Logs',
      6,
      'System-wide audit trail & CSV data export reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? prefs.getString('email') ?? 'Administrator';
      if (mounted) {
        setState(() => _adminEmail = email);
      }
    } catch (_) {}
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _navigationItems.length) {
      setState(() {
        _selectedIndex = index;
        _pageKey = UniqueKey();
      });
    }
  }

  void _refreshCurrentPage() {
    setState(() {
      _pageKey = UniqueKey();
    });
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboardView(
          key: _pageKey,
          onNavigateToModule: _onItemTapped,
        );
      case 1:
        return CampusNavigationManagementView(
          key: _pageKey,
          onBackToDashboard: () => _onItemTapped(0),
        );
      case 2:
        return AIKnowledgeBaseView(
          key: _pageKey,
          onBackToDashboard: () => _onItemTapped(0),
        );
      case 3:
        return NoticesNotificationsView(
          key: _pageKey,
          onBackToDashboard: () => _onItemTapped(0),
        );
      case 4:
        return AdminUserManagementView(
          key: _pageKey,
          onBackToDashboard: () => _onItemTapped(0),
        );
      case 5:
        return VisitorPassApprovalView(
          key: _pageKey,
          onBackToDashboard: () => _onItemTapped(0),
        );
      case 6:
        return ReportsActivityLogsView(
          key: _pageKey,
          onBackToDashboard: () => _onItemTapped(0),
        );
      default:
        return AdminDashboardView(
          key: _pageKey,
          onNavigateToModule: _onItemTapped,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        if (isDesktop) {
          // Desktop layout with persistent modern sidebar
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Row(
              children: [
                _buildSidebar(isDesktop: true),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeader(showMenuButton: false),
                      Expanded(child: _buildSelectedPage()),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Tablet & Mobile layout with drawer
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: _buildTopHeader(showMenuButton: true),
            ),
            drawer: Drawer(
              backgroundColor: AppTheme.drawerColor,
              child: _buildSidebar(isDesktop: false),
            ),
            body: _buildSelectedPage(),
          );
        }
      },
    );
  }

  Widget _buildTopHeader({required bool showMenuButton}) {
    final currentItem = _navigationItems[_selectedIndex];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.appBarColor),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Open Navigation Menu',
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Breadcrumb and current module title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      'SRIMCA AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(' / ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      currentItem.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.buttonColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  currentItem.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // System Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Atlas Connected',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.appBarColor),
            tooltip: 'Reload Module Data',
            onPressed: _refreshCurrentPage,
          ),
          const SizedBox(width: 8),
          // User profile avatar & logout
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.appBarColor,
                    child: Text(
                      _adminEmail.isNotEmpty ? _adminEmail[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _adminEmail.length > 18 ? '${_adminEmail.substring(0, 18)}...' : _adminEmail,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                      ),
                      const Text(
                        'Admin',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.logout, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isDesktop}) {
    return Container(
      width: 270,
      color: AppTheme.drawerColor,
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.buttonColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SRIMCA AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Admin Control Suite',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Seven Modules Navigation List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _navigationItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == item.index;

                return InkWell(
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context); // close drawer on mobile
                    _onItemTapped(index);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.buttonColor.withOpacity(0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppTheme.buttonColor.withOpacity(0.5))
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? AppTheme.buttonColor : Colors.white70,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.buttonColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom Logout Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Logout Session',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout Admin Session', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to end your administrator session? You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Logout'),
          ),
        ],
      ),
    );
  }
}

/// Data model for backward compatibility with existing tests or widgets
class AdminStats {
  final int totalStudents;
  final int totalFaculty;
  final int totalVisitors;
  final int activeUsers;

  const AdminStats({
    this.totalStudents = 0,
    this.totalFaculty = 0,
    this.totalVisitors = 0,
    this.activeUsers = 0,
  });

  int get totalCount => totalStudents + totalFaculty + totalVisitors;
  int get totalSystemUsers => totalStudents + totalFaculty + totalVisitors + activeUsers;

  factory AdminStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdminStats();
    return AdminStats(
      totalStudents: _parseInt(json[AdminStatsKeys.totalStudents]),
      totalFaculty: _parseInt(json[AdminStatsKeys.totalFaculty]),
      totalVisitors: _parseInt(json[AdminStatsKeys.totalVisitors]),
      activeUsers: _parseInt(json[AdminStatsKeys.activeUsers]),
    );
  }

  Map<String, dynamic> toJson() => {
    AdminStatsKeys.totalStudents: totalStudents,
    AdminStatsKeys.totalFaculty: totalFaculty,
    AdminStatsKeys.totalVisitors: totalVisitors,
    AdminStatsKeys.activeUsers: activeUsers,
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AdminStatsKeys {
  static const String totalStudents = 'total_students';
  static const String totalFaculty = 'total_faculty';
  static const String totalVisitors = 'total_visitors';
  static const String activeUsers = 'active_users';

  AdminStatsKeys._();
}
