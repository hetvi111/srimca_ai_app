import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/user_management.dart';
import 'package:srimca_ai/content_control_page.dart';
import 'package:srimca_ai/ai_monitaring_page.dart';
import 'package:srimca_ai/report_analytics_page.dart';
import 'package:srimca_ai/security_page.dart';

// API Configuration// final String backendUrl = "http://localhost:5000"; => use for pc web run
// For Android Emulator: use 'http://10.0.2.2:5000'
// For Real Phone: use your computer's local IP (run 'ipconfig' on Windows)
const String baseUrl = 'http://10.27.15.181:5000';

class DashboardService {

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/stats'));
      print('Dashboard API Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      // Return fallback data for testing
      return {
        'total_users': 3,
        'total_uploads': 0,
        'pending_uploads': 0,
        'approved_uploads': 0,
        'rejected_uploads': 0,
        'users_by_role': {
          'admins': 1,
          'faculty': 1,
          'students': 1
        },
        'recent_uploads': []
      };
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRIMCA AI Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const AdminDashboardWithSidebar(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminDashboardWithSidebar extends StatefulWidget {
  const AdminDashboardWithSidebar({super.key});

  @override
  State<AdminDashboardWithSidebar> createState() => _AdminDashboardWithSidebarState();
}

class _AdminDashboardWithSidebarState extends State<AdminDashboardWithSidebar> {
  int selectedMenuIndex = 0;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _dashboardStats = {};

  final List<SidebarMenu> sidebarMenus = [
    SidebarMenu(
      icon: Icons.dashboard,
      title: 'Dashboard',
      index: 0,
    ),
    SidebarMenu(
      icon: Icons.people,
      title: 'User Management',
      index: 1,
    ),
    SidebarMenu(
      icon: Icons.folder,
      title: 'Content Control',
      index: 2,
    ),
    SidebarMenu(
      icon: Icons.smart_toy,
      title: 'AI Monitoring',
      index: 3,
    ),
    SidebarMenu(
      icon: Icons.bar_chart,
      title: 'Reports & Analytics',
      index: 4,
    ),
    SidebarMenu(
      icon: Icons.security,
      title: 'Security',
      index: 5,
    ),
    SidebarMenu(
      icon: Icons.settings,
      title: 'System Settings',
      index: 6,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await DashboardService.getDashboardStats();
      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPage(int index) {
    setState(() {
      selectedMenuIndex = index;
    });

    switch (index) {
      case 0:
      // Dashboard - Stay on current page
        break;
      case 1:
      // User Management
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserManagementPage(),
          ),
        );
        break;
      case 2:
      // Content Control
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContentControlPage(),
          ),
        );
        break;
      case 3:
      // AI Monitoring
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AIMonitoringPage(),
          ),
        );
        break;
      case 4:
      // Reports & Analytics
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportAnalyticsPage(),
          ),
        );
        break;
      case 5:
      // Security
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SecurityPage(),
          ),
        );
        break;
      case 6:
      // System Settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System Settings - Coming Soon!')),
        );
        break;
    }
  }

  void _logout(BuildContext context) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
                    (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Loading dashboard data...',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_error != null)
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int? number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            const Text(
              'SRIMCA AI Assistant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
            color: Colors.white,
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer() : null,
      body: _isLoading && _dashboardStats.isEmpty
          ? _buildLoadingIndicator()
          : isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    final totalUsers = _dashboardStats['total_users'] ?? 0;
    final totalUploads = _dashboardStats['total_uploads'] ?? 0;
    final pendingUploads = _dashboardStats['pending_uploads'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Welcome Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E40AF),
                  const Color(0xFF3B82F6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Welcome, Admin 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage everything from one place',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                StatCard(
                  icon: Icons.people,
                  title: 'Total Users',
                  value: _formatNumber(totalUsers),
                  growth: '+${_dashboardStats['users_by_role']?['students'] ?? 0}',
                ),
                StatCard(
                  icon: Icons.folder,
                  title: 'Total Uploads',
                  value: _formatNumber(totalUploads),
                  growth: '+5%',
                ),
                StatCard(
                  icon: Icons.pending_actions,
                  title: 'Pending Review',
                  value: _formatNumber(pendingUploads),
                  growth: null,
                ),
                StatCard(
                  icon: Icons.check_circle,
                  title: 'Approved',
                  value: _formatNumber(_dashboardStats['approved_uploads'] ?? 0),
                  growth: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Distribution
          if (_dashboardStats['users_by_role'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUserDistributionRow(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    ActionCard(
                      icon: Icons.people,
                      title: 'User Management',
                      subtitle: 'Add · Edit · Roles',
                      onTap: () => _navigateToPage(1),
                    ),
                    ActionCard(
                      icon: Icons.folder,
                      title: 'Content Control',
                      subtitle: 'Approve · Update',
                      onTap: () => _navigateToPage(2),
                    ),
                    ActionCard(
                      icon: Icons.smart_toy,
                      title: 'AI Monitoring',
                      subtitle: 'Usage · Alerts',
                      onTap: () => _navigateToPage(3),
                    ),
                    ActionCard(
                      icon: Icons.bar_chart,
                      title: 'Reports & Analytics',
                      subtitle: 'Activity · Stats',
                      onTap: () => _navigateToPage(4),
                    ),
                    ActionCard(
                      icon: Icons.security,
                      title: 'Security',
                      subtitle: 'API · Backup',
                      onTap: () => _navigateToPage(5),
                    ),
                    ActionCard(
                      icon: Icons.settings,
                      title: 'System Settings',
                      subtitle: 'Configuration',
                      onTap: () => _navigateToPage(6),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Shreemad Rajchandra Institute of Management & Computer Application',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDistributionRow() {
    final usersByRole = _dashboardStats['users_by_role'] as Map<String, dynamic>?;

    if (usersByRole == null) {
      return const Text('No data available', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: [
        _buildDistributionItem('Admins', usersByRole['admins'] ?? 0, Icons.admin_panel_settings),
        _buildDistributionItem('Faculty', usersByRole['faculty'] ?? 0, Icons.person),
        _buildDistributionItem('Students', usersByRole['students'] ?? 0, Icons.school),
      ],
    );
  }

  Widget _buildDistributionItem(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Text(
            _formatNumber(count),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout() {
    final totalUsers = _dashboardStats['total_users'] ?? 0;
    final totalUploads = _dashboardStats['total_uploads'] ?? 0;
    final pendingUploads = _dashboardStats['pending_uploads'] ?? 0;

    return Row(
      children: [
        // Sidebar
        Container(
          width: 250,
          color: Colors.white,
          child: Column(
            children: [
              // Sidebar Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E40AF),
                      const Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Color(0xFF1E40AF),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SRIMCA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Menu Items
              Expanded(
                child: ListView.builder(
                  itemCount: sidebarMenus.length,
                  itemBuilder: (context, index) {
                    final menu = sidebarMenus[index];
                    final isSelected = selectedMenuIndex == index;
                    return InkWell(
                      onTap: () => _navigateToPage(menu.index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E40AF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              menu.icon,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              menu.title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[800],
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Logout Button
              Container(
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  onPressed: () => _logout(context),
                ),
              ),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Welcome Banner
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E40AF),
                        const Color(0xFF3B82F6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Welcome, Admin ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage everything from one place',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      StatCard(
                        icon: Icons.people,
                        title: 'Total Users',
                        value: _formatNumber(totalUsers),
                        growth: '+${usersByRole?['students'] ?? 0}',
                      ),
                      StatCard(
                        icon: Icons.folder,
                        title: 'Total Uploads',
                        value: _formatNumber(totalUploads),
                        growth: '+5%',
                      ),
                      StatCard(
                        icon: Icons.pending_actions,
                        title: 'Pending Review',
                        value: _formatNumber(pendingUploads),
                        growth: null,
                      ),
                      StatCard(
                        icon: Icons.check_circle,
                        title: 'Approved',
                        value: _formatNumber(_dashboardStats['approved_uploads'] ?? 0),
                        growth: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // User Distribution
                if (_dashboardStats['users_by_role'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Distribution',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildUserDistributionRow(),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.0,
                        children: [
                          ActionCard(
                            icon: Icons.people,
                            title: 'User Management',
                            subtitle: 'Add · Edit · Roles',
                            onTap: () => _navigateToPage(1),
                          ),
                          ActionCard(
                            icon: Icons.folder,
                            title: 'Content Control',
                            subtitle: 'Approve · Update',
                            onTap: () => _navigateToPage(2),
                          ),
                          ActionCard(
                            icon: Icons.smart_toy,
                            title: 'AI Monitoring',
                            subtitle: 'Usage · Alerts',
                            onTap: () => _navigateToPage(3),
                          ),
                          ActionCard(
                            icon: Icons.bar_chart,
                            title: 'Reports & Analytics',
                            subtitle: 'Activity · Stats',
                            onTap: () => _navigateToPage(4),
                          ),
                          ActionCard(
                            icon: Icons.security,
                            title: 'Security',
                            subtitle: 'API · Backup',
                            onTap: () => _navigateToPage(5),
                          ),
                          ActionCard(
                            icon: Icons.settings,
                            title: 'System Settings',
                            subtitle: 'Configuration',
                            onTap: () => _navigateToPage(6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Shreemad Rajchandra Institute of Management & Computer Application',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper to get usersByRole
  Map<String, dynamic>? get usersByRole => _dashboardStats['users_by_role'] as Map<String, dynamic>?;

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E40AF),
                    const Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFF1E40AF),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SRIMCA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Menu Items
            Expanded(
              child: ListView.builder(
                itemCount: sidebarMenus.length,
                itemBuilder: (context, index) {
                  final menu = sidebarMenus[index];
                  final isSelected = selectedMenuIndex == index;
                  return InkWell(
                    onTap: () => _navigateToPage(menu.index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E40AF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            menu.icon,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            menu.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[800],
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Logout Button
            Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarMenu {
  final IconData icon;
  final String title;
  final int index;

  SidebarMenu({
    required this.icon,
    required this.title,
    required this.index,
  });
}

// Stat Card Widget
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? growth;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.growth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  if (growth != null)
                    Text(
                      growth!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Action Card Widget
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Action Button Widget
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E40AF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: Color(0xFF1E40AF)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
    );
  }
}
