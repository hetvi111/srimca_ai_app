import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:srimca_ai/api_service.dart';

const Color kAdminPrimary = Color(0xFF001F3F); // Navy Blue
const Color kAdminAccent = Color(0xFF1E88E5); // Vibrant Blue
const Color kAdminCardBg = Colors.white;
const Color kAdminBg = Color(0xFFF8FAFC);
const Color kAdminTextDark = Color(0xFF0F172A);
const Color kAdminTextMuted = Color(0xFF64748B);

class AdminDashboardView extends StatefulWidget {
  final Function(int)? onNavigateToModule;

  const AdminDashboardView({super.key, this.onNavigateToModule});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statsData = await ApiService.getDashboardLiveStats();
      if (!mounted) return;
      if (statsData != null) {
        setState(() {
          _stats = statsData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to load live database statistics.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading stats: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kAdminAccent),
            SizedBox(height: 16),
            Text(
              'Loading live campus metrics...',
              style: TextStyle(color: kAdminTextMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: kAdminTextDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAdminAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final users = _stats?['users'] as Map<String, dynamic>? ?? {};
    final locations = _stats?['locations'] as Map<String, dynamic>? ?? {};
    final knowledge = _stats?['knowledge'] as Map<String, dynamic>? ?? {};
    final notices = _stats?['notices'] as Map<String, dynamic>? ?? {};
    final visitorPasses = _stats?['visitor_passes'] as Map<String, dynamic>? ?? {};
    final recentActivities = (_stats?['recent_activities'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final recentNotices = (_stats?['recent_notices'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final charts = _stats?['charts'] as Map<String, dynamic>? ?? {};
    final roleDist = charts['role_distribution'] as Map<String, dynamic>? ?? {};
    final monthlyReg = (charts['monthly_registrations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final isWide = MediaQuery.of(context).size.width >= 900;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: kAdminAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header & Quick Action Banner
            _buildWelcomeBanner(),
            const SizedBox(height: 24),

            // Top Live KPI Statistics Grid
            _buildMetricsGrid(users, locations, knowledge, notices, visitorPasses),
            const SizedBox(height: 24),

            // Visual Analytics Charts (Role Distribution + Registration Trend)
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildRoleDistributionChart(roleDist)),
                  const SizedBox(width: 20),
                  Expanded(flex: 7, child: _buildRegistrationTrendChart(monthlyReg)),
                ],
              )
            else ...[
              _buildRoleDistributionChart(roleDist),
              const SizedBox(height: 20),
              _buildRegistrationTrendChart(monthlyReg),
            ],
            const SizedBox(height: 24),

            // Two-column section: Recent Activities & Recent Notices
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRecentActivitiesCard(recentActivities)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildRecentNoticesCard(recentNotices)),
                ],
              )
            else ...[
              _buildRecentActivitiesCard(recentActivities),
              const SizedBox(height: 20),
              _buildRecentNoticesCard(recentNotices),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001F3F), Color(0xFF0B3B60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kAdminPrimary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SRIMCA AI Administration Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Live operational analytics, navigation endpoints, knowledge management, and visitor control.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Refresh DB'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Colors.white30),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    Map<String, dynamic> users,
    Map<String, dynamic> locations,
    Map<String, dynamic> knowledge,
    Map<String, dynamic> notices,
    Map<String, dynamic> visitorPasses,
  ) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (width < 650) {
      crossAxisCount = 1;
    } else if (width < 1100) {
      crossAxisCount = 2;
    }

    final totalUsers = users['total'] ?? 0;
    final totalLocs = locations['total'] ?? 0;
    final totalKb = knowledge['total'] ?? 0;
    final totalNotices = notices['published'] ?? 0;
    final pendingPasses = visitorPasses['pending'] ?? 0;
    final activeUsers = users['active'] ?? 0;

    final cards = [
      _buildStatCard(
        title: 'Registered Users',
        value: totalUsers.toString(),
        subtitle: '${users['students'] ?? 0} Students • ${users['faculty'] ?? 0} Faculty',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF1E88E5),
        badgeText: '$activeUsers Active',
        onTap: () => widget.onNavigateToModule?.call(4), // User Management
      ),
      _buildStatCard(
        title: 'Campus Locations',
        value: totalLocs.toString(),
        subtitle: '${locations['verified'] ?? 0} Verified GPS Points',
        icon: Icons.navigation_rounded,
        color: const Color(0xFF00897B),
        badgeText: 'Live in AI Chat',
        onTap: () => widget.onNavigateToModule?.call(1), // Campus Nav
      ),
      _buildStatCard(
        title: 'AI Knowledge Base',
        value: totalKb.toString(),
        subtitle: '${knowledge['unresolved_questions'] ?? 0} Unresolved Questions',
        icon: Icons.psychology_rounded,
        color: const Color(0xFF8E24AA),
        badgeText: knowledge['unresolved_questions'] == 0 ? 'Optimal' : 'Needs Review',
        onTap: () => widget.onNavigateToModule?.call(2), // Knowledge Base
      ),
      _buildStatCard(
        title: 'Notices & Announcements',
        value: totalNotices.toString(),
        subtitle: '${notices['active'] ?? totalNotices} Published • Active Feed',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFD32F2F),
        badgeText: 'Broadcast',
        onTap: () => widget.onNavigateToModule?.call(3), // Notices
      ),
      _buildStatCard(
        title: 'Visitor Pass Requests',
        value: pendingPasses.toString(),
        subtitle: '${visitorPasses['approved'] ?? 0} Approved • ${visitorPasses['rejected'] ?? 0} Rejected',
        icon: Icons.badge_rounded,
        color: pendingPasses > 0 ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
        badgeText: pendingPasses > 0 ? 'Pending Approval' : 'Clear',
        onTap: () => widget.onNavigateToModule?.call(5), // Visitor Passes
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) {
            final cardWidth = crossAxisCount == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
            return SizedBox(width: cardWidth, child: c);
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kAdminTextDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kAdminTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: kAdminTextMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDistributionChart(Map<String, dynamic> roleDist) {
    final students = (roleDist['students'] as num?)?.toDouble() ?? 0;
    final faculty = (roleDist['faculty'] as num?)?.toDouble() ?? 0;
    final visitors = (roleDist['visitors'] as num?)?.toDouble() ?? 0;
    final admins = (roleDist['admins'] as num?)?.toDouble() ?? 0;
    final total = students + faculty + visitors + admins;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Distribution by Role',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAdminTextDark),
              ),
              Text(
                'Total: ${total.toInt()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminAccent),
              ),
            ],
          ),
          const SizedBox(height: 20),
          total == 0
              ? const SizedBox(
                  height: 180,
                  child: Center(child: Text('No user records yet', style: TextStyle(color: kAdminTextMuted))),
                )
              : SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 38,
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFF1E88E5),
                                value: students > 0 ? students : 0.1,
                                title: '${(students / total * 100).toInt()}%',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF00897B),
                                value: faculty > 0 ? faculty : 0.1,
                                title: '${(faculty / total * 100).toInt()}%',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFFFB8C00),
                                value: visitors > 0 ? visitors : 0.1,
                                title: '${(visitors / total * 100).toInt()}%',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF8E24AA),
                                value: admins > 0 ? admins : 0.1,
                                title: '${(admins / total * 100).toInt()}%',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Students', students.toInt(), const Color(0xFF1E88E5)),
                          const SizedBox(height: 8),
                          _buildLegendItem('Faculty', faculty.toInt(), const Color(0xFF00897B)),
                          const SizedBox(height: 8),
                          _buildLegendItem('Visitors', visitors.toInt(), const Color(0xFFFB8C00)),
                          const SizedBox(height: 8),
                          _buildLegendItem('Admins', admins.toInt(), const Color(0xFF8E24AA)),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: kAdminTextDark),
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAdminTextDark),
        ),
      ],
    );
  }

  Widget _buildRegistrationTrendChart(List<Map<String, dynamic>> monthlyReg) {
    double maxY = 10;
    for (var m in monthlyReg) {
      final c = (m['count'] as num?)?.toDouble() ?? 0;
      if (c > maxY) maxY = c + 5;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Registrations (Last 6 Months)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAdminTextDark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: monthlyReg.isEmpty
                ? const Center(child: Text('No historical registration data', style: TextStyle(color: kAdminTextMuted)))
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, meta) {
                              return Text(
                                val.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: kAdminTextMuted),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < monthlyReg.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    monthlyReg[idx]['month']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 11, color: kAdminTextMuted),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(monthlyReg.length, (i) {
                        final count = (monthlyReg[i]['count'] as num?)?.toDouble() ?? 0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: count,
                              color: kAdminAccent,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard(List<Map<String, dynamic>> activities) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 20, color: kAdminPrimary),
                  SizedBox(width: 8),
                  Text('Audit Activity Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAdminTextDark)),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigateToModule?.call(6), // Reports & Logs
                child: const Text('View All', style: TextStyle(fontSize: 12, color: kAdminAccent)),
              ),
            ],
          ),
          const Divider(height: 20),
          activities.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No administrative activity recorded yet.', style: TextStyle(color: kAdminTextMuted))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length > 5 ? 5 : activities.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final item = activities[i];
                    final action = (item['action'] ?? '').toString();
                    final module = (item['module'] ?? '').toString();
                    final record = (item['affected_record'] ?? '').toString();
                    final user = (item['acting_user'] ?? 'Admin').toString();
                    final timeStr = item['created_at']?.toString() ?? '';

                    Color badgeColor = Colors.blueGrey;
                    if (action.contains('CREATE') || action.contains('APPROVE') || action.contains('PUBLISH')) {
                      badgeColor = Colors.green;
                    } else if (action.contains('DELETE') || action.contains('REJECT')) {
                      badgeColor = Colors.redAccent;
                    } else if (action.contains('UPDATE') || action.contains('RESOLVE')) {
                      badgeColor = Colors.orange;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            action,
                            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$module: $record',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminTextDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'by $user • ${_formatDate(timeStr)}',
                                style: const TextStyle(fontSize: 11, color: kAdminTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRecentNoticesCard(List<Map<String, dynamic>> notices) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded, size: 20, color: kAdminPrimary),
                  SizedBox(width: 8),
                  Text('Recent Notices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAdminTextDark)),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigateToModule?.call(3), // Notices
                child: const Text('Manage', style: TextStyle(fontSize: 12, color: kAdminAccent)),
              ),
            ],
          ),
          const Divider(height: 20),
          notices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No notices published yet.', style: TextStyle(color: kAdminTextMuted))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notices.length > 5 ? 5 : notices.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final item = notices[i];
                    final title = item['title']?.toString() ?? 'Notice';
                    final category = (item['category'] ?? 'notice').toString();
                    final target = (item['target_role'] ?? 'all').toString();
                    final timeStr = item['created_at']?.toString() ?? '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kAdminAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notifications_active_outlined, color: kAdminAccent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminTextDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    category.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAdminAccent),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('• Target: $target • ${_formatDate(timeStr)}',
                                      style: const TextStyle(fontSize: 11, color: kAdminTextMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
