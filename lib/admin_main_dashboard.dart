import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'student_management_page.dart';
import 'faculty_management_page.dart';
import 'visitor_management_page.dart';
import 'content_management_page.dart';
import 'ai_monitoring_page.dart';
import 'reports_analytics_page.dart';
import 'notifications_page.dart';
import 'database_management_page.dart';
import 'user_management.dart';
import 'api_service.dart';

// Theme colors based on requirements
class AppTheme {
  static const Color appBarColor = Color(0xFF1A237E); // Navy Blue
  static const Color drawerColor = Color(0xFF283593); // Navy Blue (slightly lighter)
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF5F5F5); // Light Grey
  static const Color buttonColor = Color(0xFF1E88E5); // Blue
  static const Color textColor = Color(0xFF212121); // Black / Dark Grey
}

/// ================== ADMIN MAIN DASHBOARD ==================
class AdminMainDashboard extends StatefulWidget {
  const AdminMainDashboard({super.key});

  @override
  State<AdminMainDashboard> createState() => _AdminMainDashboardState();
}

class _AdminMainDashboardState extends State<AdminMainDashboard> {
  int _selectedIndex = 0;
  
  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.home, 'Home', 0),
    NavigationItem(Icons.school, 'Students', 1),
    NavigationItem(Icons.person, 'Faculty', 2),
    NavigationItem(Icons.badge, 'Visitors', 3),
    NavigationItem(Icons.folder, 'Content', 4),
    NavigationItem(Icons.monitor, 'AI Monitor', 5),
    NavigationItem(Icons.bar_chart, 'Reports', 6),
    NavigationItem(Icons.notifications, 'Notifications', 7),
    NavigationItem(Icons.storage, 'Database', 8),
  ];

  final List<Widget> _pages = [
    const AdminHomePage(),
    const StudentManagementPage(),
    const FacultyManagementPage(),
    const VisitorManagementPage(),
    const ContentManagementPage(),
    const AIMonitoringPage(),
    const ReportsAnalyticsPage(),
    const NotificationsPage(),
    const DatabaseManagementPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        foregroundColor: Colors.white,
        title: Text(
          'SRIMCA Admin - ${_navigationItems[_selectedIndex].title}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.drawerColor,
      child: Column(
        children: [
          // Admin Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 40, color: AppTheme.appBarColor),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Administrator',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'SRIMCA AI Assistant',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == item.index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? AppTheme.buttonColor : Colors.white70,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.white10,
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(index);
                  },
                );
              },
            ),
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Data model for admin dashboard statistics
/// Provides type-safe access to all stat fields with default values
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

  /// Calculate total count of all users (students + faculty + visitors)
  int get totalCount => totalStudents + totalFaculty + totalVisitors;

  /// Calculate total system users including active users
  int get totalSystemUsers => totalStudents + totalFaculty + totalVisitors + activeUsers;

  /// Create AdminStats from JSON response with null safety
  factory AdminStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AdminStats();
    }
    return AdminStats(
      totalStudents: _parseInt(json[AdminStatsKeys.totalStudents]),
      totalFaculty: _parseInt(json[AdminStatsKeys.totalFaculty]),
      totalVisitors: _parseInt(json[AdminStatsKeys.totalVisitors]),
      activeUsers: _parseInt(json[AdminStatsKeys.activeUsers]),
    );
  }

  /// Convert to JSON map for serialization
  Map<String, dynamic> toJson() => {
        AdminStatsKeys.totalStudents: totalStudents,
        AdminStatsKeys.totalFaculty: totalFaculty,
        AdminStatsKeys.totalVisitors: totalVisitors,
        AdminStatsKeys.activeUsers: activeUsers,
      };

  /// Parse integer safely with fallback to 0
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Create a copy with optional field overrides
  AdminStats copyWith({
    int? totalStudents,
    int? totalFaculty,
    int? totalVisitors,
    int? activeUsers,
  }) {
    return AdminStats(
      totalStudents: totalStudents ?? this.totalStudents,
      totalFaculty: totalFaculty ?? this.totalFaculty,
      totalVisitors: totalVisitors ?? this.totalVisitors,
      activeUsers: activeUsers ?? this.activeUsers,
    );
  }

  @override
  String toString() {
    return 'AdminStats(students: $totalStudents, faculty: $totalFaculty, visitors: $totalVisitors, active: $activeUsers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminStats &&
        other.totalStudents == totalStudents &&
        other.totalFaculty == totalFaculty &&
        other.totalVisitors == totalVisitors &&
        other.activeUsers == activeUsers;
  }

  @override
  int get hashCode {
    return Object.hash(totalStudents, totalFaculty, totalVisitors, activeUsers);
  }
}

/// Static keys for admin stats - prevents magic strings and typos
class AdminStatsKeys {
  static const String totalStudents = 'total_students';
  static const String totalFaculty = 'total_faculty';
  static const String totalVisitors = 'total_visitors';
  static const String activeUsers = 'active_users';

  // Private constructor to prevent instantiation
  AdminStatsKeys._();
}

/// Navigation Item Model for drawer navigation
class NavigationItem {
  final IconData icon;
  final String title;
  final int index;

  const NavigationItem(this.icon, this.title, this.index);
}

/// ================== ADMIN HOME PAGE ==================
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // Use AdminStats model instead of raw Map for type safety and maintainability
  AdminStats _stats = const AdminStats();
  bool _isLoading = true;
  String? _errorMessage; // Track error state for better UX

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Prevent multiple concurrent requests
    if (_isLoading && _stats.totalCount > 0) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final stats = await ApiService.getAdminStats();
      
      debugPrint('Raw stats from API: $stats');
      
      // Use AdminStats.fromJson for type-safe parsing with null safety
      final adminStats = AdminStats.fromJson(stats);
      
      debugPrint('Parsed AdminStats: $adminStats');
      debugPrint('Total Students: ${adminStats.totalStudents}');
      debugPrint('Total Faculty: ${adminStats.totalFaculty}');
      debugPrint('Total Visitors: ${adminStats.totalVisitors}');
      debugPrint('Active Users: ${adminStats.activeUsers}');
      
      setState(() {
        _stats = adminStats;
        _isLoading = false;
      });
    } catch (e) {
      // Proper error handling with user-friendly error state
      debugPrint('Error loading stats: $e'); // Use debugPrint for debug logs
      setState(() {
        _stats = const AdminStats(); // Reset to default values
        _errorMessage = 'Failed to load statistics. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome Card
            Card(
              color: AppTheme.cardColor,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.appBarColor,
                      child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Administrator!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Manage your SRIMCA AI Assistant System',
                            style: TextStyle(fontSize: 14, color: AppTheme.textColor.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Quick Stats
            const Text('Quick Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            const SizedBox(height: 15),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
                children: [
                  // Using AdminStats model for type-safe access
                  _buildStatCard(
                    'Total Students', 
                    _stats.totalStudents, 
                    Icons.school, 
                    Colors.blue,
                    showTotal: true,
                    totalLabel: 'Total Users',
                    totalValue: _stats.totalCount,
                  ),
                  _buildStatCard(
                    'Total Faculty', 
                    _stats.totalFaculty, 
                    Icons.person, 
                    Colors.green,
                    showTotal: true,
                    totalLabel: 'Total Users',
                    totalValue: _stats.totalCount,
                  ),
                  _buildStatCard(
                    'Total Visitors', 
                    _stats.totalVisitors, 
                    Icons.badge, 
                    Colors.orange,
                    showTotal: true,
                    totalLabel: 'Total Users',
                    totalValue: _stats.totalCount,
                  ),
                  _buildStatCard(
                    'Active Users', 
                    _stats.activeUsers, 
                    Icons.people, 
                    Colors.purple,
                    showTotal: true,
                    totalLabel: 'System Total',
                    totalValue: _stats.totalSystemUsers,
                  ),
                ],
              ),
            const SizedBox(height: 25),
            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildActionCard(context, 'Add Student', Icons.person_add, () {}),
                _buildActionCard(context, 'Add Faculty', Icons.person_add, () {}),
                _buildActionCard(context, 'Post Notice', Icons.campaign, () {}),
                _buildActionCard(context, 'Upload Material', Icons.upload_file, () {}),
                _buildActionCard(context, 'View Reports', Icons.assessment, () {}),
                _buildActionCard(context, 'Send Notification', Icons.notifications_active, () {}),
                _buildActionCard(context, 'Password Requests', Icons.lock_reset, () {
                  Navigator.pushNamed(context, '/admin-password-requests');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a stat card with optional total count display
  /// Parameters:
  /// - [title]: The card title
  /// - [value]: The main count value
  /// - [icon]: Icon to display
  /// - [color]: Theme color for the card
  /// - [showTotal]: Whether to show total count
  /// - [totalLabel]: Label for total (e.g., 'Total Users')
  /// - [totalValue]: The total count value
  Widget _buildStatCard(
    String title, 
    int value, 
    IconData icon, 
    Color color, {
    bool showTotal = false,
    String? totalLabel,
    int? totalValue,
  }) {
    // Format numbers with thousand separators for readability
    final formattedValue = _formatNumber(value);
    final formattedTotal = totalValue != null ? _formatNumber(totalValue) : '0';
    
    return Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate based on title
          if (title.contains('Students')) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementPage()));
          } else if (title.contains('Faculty')) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultyManagementPage()));
          } else if (title.contains('Visitors')) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorManagementPage()));
          } else if (title.contains('Active')) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage()));
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formattedValue, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                      if (showTotal && totalLabel != null)
                        Text(
                          '$totalLabel: $formattedTotal',
                          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textColor)),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: AppTheme.cardColor,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.buttonColor, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format number with thousand separators for better readability
  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    final String str = number.toString();
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }
}

/// Build an error card with retry option
Widget _buildErrorCard(String message) {
  return Card(
    color: Colors.red.shade50,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {}, // Will be connected to refresh
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
