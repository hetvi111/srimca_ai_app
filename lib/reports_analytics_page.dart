import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= REPORTS & ANALYTICS PAGE =================
class ReportsAnalyticsPage extends StatefulWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  State<ReportsAnalyticsPage> createState() => _ReportsAnalyticsPageState();
}

class _ReportsAnalyticsPageState extends State<ReportsAnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _overview = {
    'total_users': 0,
    'active_today': 0,
    'total_queries': 0,
    'avg_response': '<2s',
  };
  Map<String, dynamic> _distribution = {
    'students': 0,
    'faculty': 0,
    'visitors': 0,
    'admins': 0,
  };
  List<Map<String, dynamic>> _monthlyActivity = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final data = await ApiService.getReportsAnalytics();
    if (!mounted) return;
    setState(() {
      _overview = (data['overview'] as Map<String, dynamic>? ?? _overview);
      _distribution = (data['distribution'] as Map<String, dynamic>? ?? _distribution);
      _monthlyActivity = (data['monthly_activity'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Analytics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildCard("Total Users", _overview['total_users'].toString(), Icons.people, Colors.blue),
                _buildCard("Active Today", _overview['active_today'].toString(), Icons.today, Colors.green),
                _buildCard("Total Queries", _overview['total_queries'].toString(), Icons.chat, Colors.orange),
                _buildCard("Avg Response", (_overview['avg_response'] ?? '<2s').toString(), Icons.timer, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            
            // User Distribution
            const Text("User Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDistributionCard("Students", (_distribution['students'] as num?)?.toInt() ?? 0, Colors.blue),
            const SizedBox(height: 8),
            _buildDistributionCard("Faculty", (_distribution['faculty'] as num?)?.toInt() ?? 0, Colors.green),
            const SizedBox(height: 8),
            _buildDistributionCard("Visitors", (_distribution['visitors'] as num?)?.toInt() ?? 0, Colors.orange),
            const SizedBox(height: 8),
            _buildDistributionCard("Admins", (_distribution['admins'] as num?)?.toInt() ?? 0, Colors.purple),
            
            const SizedBox(height: 24),
            
            // Monthly Activity
            const Text("Monthly Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _monthlyActivity.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text("No monthly activity data", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : Column(
                      children: _monthlyActivity
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: Text(item['month']?.toString() ?? ''),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: _monthlyProgressValue((item['queries'] as num?)?.toInt() ?? 0),
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(8),
                                      backgroundColor: Colors.grey[300],
                                      color: const Color(0xFF1A237E),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    ((item['queries'] as num?)?.toInt() ?? 0).toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Export Options
            const Text("Export Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Excel"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _monthlyProgressValue(int queries) {
    if (_monthlyActivity.isEmpty) return 0;
    final maxQueries = _monthlyActivity
        .map((e) => (e['queries'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);
    if (maxQueries <= 0) return 0;
    return queries / maxQueries;
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
