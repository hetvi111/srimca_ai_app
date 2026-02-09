import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

const String baseUrl = 'http://10.27.15.181:5000';


class ReportAnalyticsPage extends StatefulWidget {
  const ReportAnalyticsPage({super.key});

  @override
  State<ReportAnalyticsPage> createState() => _ReportAnalyticsPageState();
}

class _ReportAnalyticsPageState extends State<ReportAnalyticsPage> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic> reportsData = {};

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/reports'));
      if (response.statusCode == 200) {
        setState(() {
          reportsData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
        // Fallback data
        reportsData = {
          'total_queries': 1650,
          'daily_usage': [65, 100, 150, 100, 80, 40, 30],
          'user_stats': {'admins': 5, 'faculty': 20, 'students': 150},
        };
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(error ?? 'Loading reports...', style: const TextStyle(color: Colors.grey)),
          if (error != null)
            ElevatedButton(
              onPressed: fetchReports,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQueries = reportsData['total_queries'] ?? 0;
    final List<dynamic> rawDailyUsage =
    reportsData['daily_usage'] ?? [65, 100, 150, 100, 80, 40, 30];

final List<int> dailyUsage =
    rawDailyUsage.map((e) => int.tryParse(e.toString()) ?? 0).toList();

    final userStats = reportsData['user_stats'] as Map<String, dynamic>? ?? {'admins': 5, 'faculty': 20, 'students': 150};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Reports & Analytics"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchReports,
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading && reportsData.isEmpty
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _overviewCards(totalQueries, userStats),
            const SizedBox(height: 20),

            /// Charts in columns
           Row(
  children: [
    Expanded(
      child: ChartContainer(
        title: "Daily Usage",
        child: BarChartCard(dailyUsage: dailyUsage),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(child: DonutChartCard(userStats: userStats)),
  ],
),

            const SizedBox(height: 30),

            /// Faculty Contribution Reports
            const FacultyContributionSection(),

            const SizedBox(height: 24),

            /// Generate Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📊 Report generated successfully!')),
                );
              },
              child: const Text(
                "Generate Report",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewCards(int totalQueries, Map<String, dynamic> userStats) {
    final activeUsers = (userStats['admins'] ?? 0) + (userStats['faculty'] ?? 0) + (userStats['students'] ?? 0);
    final approvedContent = activeUsers + 100; // Mock calculation

    return Row(
      children: [
        Expanded(
          child: InfoCard(
            title: "Active Users",
            value: activeUsers.toString(),
            growth: "+8%",
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoCard(
            title: "Approved Content",
            value: approvedContent.toString(),
            growth: "+12%",
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoCard(
            title: "Total Queries",
            value: totalQueries.toString(),
            growth: "+5%",
            icon: Icons.search,
          ),
        ),
      ],
    );
  }
}

/* ---------------- INFO CARD ---------------- */

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String growth;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.growth,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(growth, style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

/* ---------------- BAR CHART ---------------- */

class BarChartCard extends StatelessWidget {
  final List<int> dailyUsage;

  const BarChartCard({super.key, required this.dailyUsage});

  @override
  Widget build(BuildContext context) {
    final maxValue =
        dailyUsage.isNotEmpty ? dailyUsage.reduce((a, b) => a > b ? a : b) : 100;
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(dailyUsage.length, (index) {
              final height = (dailyUsage[index] / maxValue) * 150;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade700
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dailyUsage[index].toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(labels.length, (index) {
            return SizedBox(
              width: 24,
              child: Text(
                labels[index],
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/* ---------------- DONUT CHART ---------------- */

class DonutChartCard extends StatelessWidget {
  final Map<String, dynamic> userStats;

  const DonutChartCard({super.key, required this.userStats});

  @override
  Widget build(BuildContext context) {
    final admins = (userStats['admins'] ?? 0).toDouble();
    final faculty = (userStats['faculty'] ?? 0).toDouble();
    final students = (userStats['students'] ?? 0).toDouble();
    final total = admins + faculty + students;

    if (total == 0) {
      return ChartContainer(
        title: "User Distribution",
        child: const Center(child: Text("No data available")),
      );
    }

    final data = [
      {'label': 'Admins', 'value': admins, 'color': Colors.blue, 'count': userStats['admins'] ?? 0},
      {'label': 'Faculty', 'value': faculty, 'color': Colors.green, 'count': userStats['faculty'] ?? 0},
      {'label': 'Students', 'value': students, 'color': Colors.orange, 'count': userStats['students'] ?? 0},
    ]..removeWhere((item) => item['value'] == 0);

    return ChartContainer(
      title: "User Distribution",
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(150, 150),
              painter: DonutChartPainter(data: data, total: total),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map((item) {
              final percentage = ((item['value'] as double) / total * 100).toStringAsFixed(0);
              return _legendItem(
                item['label'] as String,
                item['color'] as Color,
                item['count'] as int,
                '$percentage%',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, int count, String percentage) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
        Text('$count ($percentage)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double total;

  DonutChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item['value'] as double) / total * 2 * math.pi;
      paint.color = item['color'] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ---------------- CHART CONTAINER ---------------- */

class ChartContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const ChartContainer({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/* ---------------- FACULTY CONTRIBUTION TABLE ---------------- */

class FacultyContributionSection extends StatelessWidget {
  const FacultyContributionSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock faculty data - in real app, fetch from backend
    final facultyData = [
      {'name': 'Dr. Emma Johnson', 'uploads': 25, 'approved': 22, 'pending': 3},
      {'name': 'Prof. John Smith', 'uploads': 18, 'approved': 16, 'pending': 2},
      {'name': 'Dr. Sarah Brown', 'uploads': 15, 'approved': 15, 'pending': 0},
      {'name': 'Prof. Laura Wilson', 'uploads': 12, 'approved': 8, 'pending': 4},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Faculty Contribution Reports",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _headerRow(),
          const Divider(),
          ...facultyData.map((faculty) => _row(
            faculty['name'] as String,
            faculty['uploads'] as int,
            faculty['approved'] as int,
            faculty['pending'] as int,
          )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Showing 1 to 4 of 10 records",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Pagination(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: const [
        Expanded(flex: 3, child: Text("Faculty")),
        Expanded(child: Text("Uploads")),
        Expanded(child: Text("Approved")),
        Expanded(child: Text("Pending")),
        SizedBox(width: 60),
      ],
    );
  }

  Widget _row(String name, int uploads, int approved, int pending) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          ),
          Expanded(child: Text("$uploads")),
          Expanded(child: Text("$approved")),
          Expanded(child: Text("$pending")),
          Row(
            children: [
              _icon(Icons.edit, Colors.blue),
              const SizedBox(width: 6),
              _icon(Icons.delete, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}

/* ---------------- PAGINATION ---------------- */

class Pagination extends StatelessWidget {
  const Pagination({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _page("1", true),
        _page("2", false),
        _page("3", false),
      ],
    );
  }

  Widget _page(String text, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        text,
        style: TextStyle(color: active ? Colors.white : Colors.blue),
      ),
    );
  }
}
