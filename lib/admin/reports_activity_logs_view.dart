import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srimca_ai/api_service.dart';

class ReportsActivityLogsView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const ReportsActivityLogsView({super.key, this.onBackToDashboard});

  @override
  State<ReportsActivityLogsView> createState() => _ReportsActivityLogsViewState();
}

class _ReportsActivityLogsViewState extends State<ReportsActivityLogsView> with SingleTickerProviderStateMixin {
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color bgLight = Color(0xFFF8F9FA);

  late TabController _tabController;

  // Reports state
  bool _isLoadingReports = true;
  String? _reportsError;
  String _selectedTimeframe = '30days'; // 7days, 30days, all
  Map<String, dynamic>? _reportsData;

  // Logs state
  bool _isLoadingLogs = true;
  String? _logsError;
  List<Map<String, dynamic>> _activityLogs = [];
  String _logSearchQuery = '';
  String _selectedLogModule = 'all';
  String _selectedLogAction = 'all';
  final TextEditingController _logSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReports();
    _fetchActivityLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoadingReports = true;
      _reportsError = null;
    });

    try {
      final data = await ApiService.getAdminReportsSummary(timeframe: _selectedTimeframe);
      setState(() {
        _reportsData = data;
        _isLoadingReports = false;
      });
    } catch (e) {
      setState(() {
        _reportsError = 'Failed to load report summary: $e';
        _isLoadingReports = false;
      });
    }
  }

  Future<void> _fetchActivityLogs() async {
    setState(() {
      _isLoadingLogs = true;
      _logsError = null;
    });

    try {
      final logs = await ApiService.getAdminActivityLogs(
        search: _logSearchQuery.isNotEmpty ? _logSearchQuery : null,
        module: _selectedLogModule == 'all' ? null : _selectedLogModule,
        action: _selectedLogAction == 'all' ? null : _selectedLogAction,
      );

      setState(() {
        _activityLogs = logs;
        _isLoadingLogs = false;
      });
    } catch (e) {
      setState(() {
        _logsError = 'Failed to load audit logs: $e';
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _exportCsv(String reportType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final csvContent = await ApiService.exportReportCsv(reportType);
      if (mounted) Navigator.pop(context); // Dismiss loading

      if (csvContent != null && mounted) {
        _showCsvPreviewDialog(reportType, csvContent);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate CSV export'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCsvPreviewDialog(String reportType, String csv) {
    showDialog(
      context: context,
      builder: (ctx) {
        final lineCount = csv.split('\n').length;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.table_chart_outlined, color: primaryNavy),
              const SizedBox(width: 8),
              Text(
                '${reportType.toUpperCase()} Export ($lineCount rows)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formatted CSV output ready for download or import into Excel/Sheets:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csv,
                        style: const TextStyle(
                          color: Color(0xFFD4D4D4),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy to Clipboard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            SizedBox(
              height: 750,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReportsTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBackToDashboard != null) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryNavy),
            onPressed: widget.onBackToDashboard,
            tooltip: 'Back to Dashboard',
          ),
          const SizedBox(width: 8),
        ],
        const Icon(Icons.analytics_outlined, color: primaryNavy, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports & Activity Logs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'System-wide operational metrics, audit activity trail, and CSV data exports',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _fetchReports();
            _fetchActivityLogs();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryNavy,
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: primaryNavy,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: primaryNavy,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'System Reports & Metrics'),
          Tab(icon: Icon(Icons.history, size: 18), text: 'Audit Activity Logs'),
        ],
      ),
    );
  }

  // --- TAB 1: System Reports ---
  Widget _buildReportsTab() {
    if (_isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(_reportsError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchReports, child: const Text('Retry')),
          ],
        ),
      );
    }

    final reports = _reportsData ?? {};
    final usersRep = reports['users'] as Map<String, dynamic>? ?? {};
    final locsRep = reports['locations'] as Map<String, dynamic>? ?? {};
    final kbRep = reports['knowledge_base'] as Map<String, dynamic>? ?? {};
    final noticesRep = reports['notices'] as Map<String, dynamic>? ?? {};
    final passesRep = reports['visitor_passes'] as Map<String, dynamic>? ?? {};
    final aiRep = reports['ai_chat'] as Map<String, dynamic>? ?? {};

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Timeframe Range: ', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTimeframe,
                      items: const [
                        DropdownMenuItem(value: '7days', child: Text('Past 7 Days')),
                        DropdownMenuItem(value: '30days', child: Text('Past 30 Days')),
                        DropdownMenuItem(value: 'all', child: Text('All Time')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTimeframe = val);
                          _fetchReports();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickExportButton('Export Users', 'users', Icons.people),
                _buildQuickExportButton('Export Locations', 'locations', Icons.map),
                _buildQuickExportButton('Export KB', 'knowledge', Icons.school),
                _buildQuickExportButton('Export Notices', 'notices', Icons.campaign),
                _buildQuickExportButton('Export Visitors', 'visitors', Icons.badge),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: [
                _buildReportCard(
                  title: 'User Accounts',
                  icon: Icons.people_outline,
                  color: Colors.blue,
                  exportKey: 'users',
                  items: [
                    'Registered in period: ${usersRep['registered_in_period'] ?? 0}',
                    'Students: ${usersRep['students'] ?? 0}',
                    'Faculty: ${usersRep['faculty'] ?? 0}',
                    'Visitors: ${usersRep['visitors'] ?? 0}',
                    'Admins: ${usersRep['admins'] ?? 0}',
                  ],
                ),
                _buildReportCard(
                  title: 'Campus Locations',
                  icon: Icons.place_outlined,
                  color: Colors.teal,
                  exportKey: 'locations',
                  items: [
                    'Total landmarks: ${locsRep['total'] ?? 0}',
                    'GPS Verified: ${locsRep['verified'] ?? 0}',
                    'Pending Coordinates: ${locsRep['unverified'] ?? 0}',
                    'Categories: Academic, Amenities, Sports',
                  ],
                ),
                _buildReportCard(
                  title: 'AI Knowledge Base',
                  icon: Icons.school_outlined,
                  color: Colors.purple,
                  exportKey: 'knowledge',
                  items: [
                    'Official entries: ${kbRep['total_entries'] ?? 0}',
                    'Resolved queries: ${kbRep['resolved_questions'] ?? 0}',
                    'Pending review: ${kbRep['pending_questions'] ?? 0}',
                    'Categories: Courses, Faculty, Rules, FAQs',
                  ],
                ),
                _buildReportCard(
                  title: 'Notices & Announcements',
                  icon: Icons.campaign_outlined,
                  color: Colors.amber[800]!,
                  exportKey: 'notices',
                  items: [
                    'Created in period: ${noticesRep['created_in_period'] ?? 0}',
                    'Total active published: ${noticesRep['total_published'] ?? 0}',
                    'Targeting: Students, Faculty, Visitors, All',
                  ],
                ),
                _buildReportCard(
                  title: 'Visitor Pass Applications',
                  icon: Icons.badge_outlined,
                  color: Colors.green,
                  exportKey: 'visitors',
                  items: [
                    'Approved Passes: ${passesRep['approved'] ?? 0}',
                    'Pending Review: ${passesRep['pending'] ?? 0}',
                    'Rejected Requests: ${passesRep['rejected'] ?? 0}',
                    'Security: Cryptographic QR Tokens',
                  ],
                ),
                _buildReportCard(
                  title: 'AI Chat Performance',
                  icon: Icons.smart_toy_outlined,
                  color: Colors.indigo,
                  items: [
                    'Total Queries Asked: ${aiRep['total_queries'] ?? 0}',
                    'Queries in timeframe: ${aiRep['queries_in_period'] ?? 0}',
                    'Direct KB Retrieval: Enabled',
                    'Zero Fact Hallucination: Enforced',
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickExportButton(String label, String reportKey, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () => _exportCsv(reportKey),
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryNavy,
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    String? exportKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
              ),
              if (exportKey != null)
                IconButton(
                  icon: const Icon(Icons.download, size: 18),
                  tooltip: 'Export CSV',
                  color: Colors.grey[600],
                  onPressed: () => _exportCsv(exportKey),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: items.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          it,
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Audit Activity Logs ---
  Widget _buildLogsTab() {
    return Column(
      children: [
        _buildLogFiltersBar(),
        const SizedBox(height: 12),
        Expanded(child: _buildLogList()),
      ],
    );
  }

  Widget _buildLogFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _logSearchController,
              decoration: InputDecoration(
                hintText: 'Search logs by admin email, affected record, or action...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _logSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _logSearchQuery = '';
                            _logSearchController.clear();
                          });
                          _fetchActivityLogs();
                        },
                      )
                    : null,
                filled: true,
                fillColor: bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) {
                setState(() => _logSearchQuery = val.trim());
                _fetchActivityLogs();
              },
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLogModule,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Modules', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Campus Navigation', child: Text('Campus Nav', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'AI Knowledge Base', child: Text('Knowledge Base', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Notices & Notifications', child: Text('Notices', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'User Management', child: Text('Users', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Visitor Pass Approval', child: Text('Visitor Passes', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLogModule = val);
                    _fetchActivityLogs();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLogAction,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Actions', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'CREATE', child: Text('CREATE', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'UPDATE', child: Text('UPDATE', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'DELETE', child: Text('DELETE', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'APPROVE', child: Text('APPROVE', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'REJECT', child: Text('REJECT', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'PUBLISH', child: Text('PUBLISH', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLogAction = val);
                    _fetchActivityLogs();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _exportCsv('activity_logs'),
            icon: const Icon(Icons.download, size: 15),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_isLoadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(_logsError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchActivityLogs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_activityLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No activity logs found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            const SizedBox(height: 4),
            Text(
              'Administrative actions like adding locations, creating notices, or approving passes will be recorded here.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _activityLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _activityLogs[index];
        final action = (log['action'] ?? 'ACTION').toString().toUpperCase();
        final module = log['module'] ?? 'System';
        final actingUser = log['acting_user'] ?? 'Admin';
        final affected = log['affected_record'] ?? '';
        final details = log['details'] ?? '';
        final timestamp = log['timestamp'] ?? '';

        Color actionColor;
        switch (action) {
          case 'CREATE':
          case 'APPROVE':
          case 'PUBLISH':
          case 'ACTIVATE':
            actionColor = const Color(0xFF2E7D32);
            break;
          case 'DELETE':
          case 'REJECT':
          case 'DEACTIVATE':
            actionColor = const Color(0xFFC62828);
            break;
          case 'UPDATE':
          case 'DRAFT':
            actionColor = const Color(0xFF1E88E5);
            break;
          default:
            actionColor = Colors.grey[700]!;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: actionColor.withOpacity(0.3)),
                ),
                child: Text(
                  action,
                  style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          module,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryNavy),
                        ),
                        if (affected.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• $affected',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details.isNotEmpty ? details : 'Action executed by $actingUser',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    actingUser,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timestamp.isNotEmpty ? timestamp.split('.')[0] : '',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
