import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// For Android Emulator: use 'http://10.0.2.2:5000'
// For Real Phone: use your computer's local IP (run 'ipconfig' on Windows)
const String baseUrl = 'http://10.27.15.181:5000';
 // Change to your IP for real phone

// FAQ Model
class FAQItem {
  final String id;
  final String question;
  final String? answer;

  FAQItem({required this.id, required this.question, this.answer});
}

// Alert Model
class LowConfidenceAlert {
  final String id;
  final String question;
  final int confidence;
  final int confidenceLevel;
  final String status;

  LowConfidenceAlert({
    required this.id,
    required this.question,
    required this.confidence,
    required this.confidenceLevel,
    required this.status,
  });

  factory LowConfidenceAlert.fromJson(Map<String, dynamic> json) {
    return LowConfidenceAlert(
      id: json['_id'] ?? json['id'] ?? '',
      question: json['question'] ?? 'Unknown question',
      confidence: json['confidence'] ?? 0,
      confidenceLevel: json['confidence_level'] ?? json['confidenceLevel'] ?? 50,
      status: json['status'] ?? 'pending',
    );
  }
}

class AIMonitoringPage extends StatefulWidget {
  const AIMonitoringPage({super.key});

  @override
  State<AIMonitoringPage> createState() => _AIMonitoringPageState();
}

class _AIMonitoringPageState extends State<AIMonitoringPage> {
  String selectedTimeRange = 'Last Week';
  String selectedDailyRange = 'Last Week';
  int currentAlertPage = 1;
  final int alertsPerPage = 3;
  bool isLoading = true;
  String? error;

  List<FAQItem> frequentlyAskedQuestions = [];
  List<LowConfidenceAlert> lowConfidenceAlerts = [];
  Map<String, dynamic> reportsData = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Fetch FAQs
      final faqResponse = await http.get(Uri.parse('$baseUrl/faqs'));
      if (faqResponse.statusCode == 200) {
        final List<dynamic> faqData = json.decode(faqResponse.body);
        frequentlyAskedQuestions = faqData.map((json) => FAQItem(
          id: json['_id'] ?? '',
          question: json['question'] ?? '',
          answer: json['answer'],
        )).toList();
      }

      // Fetch Alerts
      final alertResponse = await http.get(Uri.parse('$baseUrl/alerts'));
      if (alertResponse.statusCode == 200) {
        final List<dynamic> alertData = json.decode(alertResponse.body);
        lowConfidenceAlerts = alertData.map((json) => LowConfidenceAlert.fromJson(json)).toList();
      }

      // Fetch Reports
      final reportResponse = await http.get(Uri.parse('$baseUrl/reports'));
      if (reportResponse.statusCode == 200) {
        reportsData = json.decode(reportResponse.body);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching AI monitoring data: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
        // Fallback data
        frequentlyAskedQuestions = [
          FAQItem(id: '1', question: 'How does the AI system work?'),
          FAQItem(id: '2', question: 'How can I reset my password?'),
          FAQItem(id: '3', question: 'Where can I view my recent orders?'),
          FAQItem(id: '4', question: 'What services do you offer?'),
        ];
        lowConfidenceAlerts = [
          LowConfidenceAlert(id: '1', question: 'Is there home delivery available?', confidence: 49, confidenceLevel: 35, status: 'pending'),
          LowConfidenceAlert(id: '2', question: 'What is ML and how it works?', confidence: 35, confidenceLevel: 45, status: 'pending'),
          LowConfidenceAlert(id: '3', question: 'How to use the API?', confidence: 40, confidenceLevel: 50, status: 'pending'),
        ];
        reportsData = {
          'total_queries': 1650,
          'daily_usage': [65, 100, 150, 100, 80, 40, 30],
        };
      });
    }
  }

  Future<void> approveAlert(String id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/alerts/approve/$id'));
      if (response.statusCode == 200) {
        setState(() {
          lowConfidenceAlerts.removeWhere((alert) => alert.id == id);
        });
      }
    } catch (e) {
      // Fallback: remove locally
      setState(() {
        lowConfidenceAlerts.removeWhere((alert) => alert.id == id);
      });
    }
  }

  List<LowConfidenceAlert> get paginatedAlerts {
    final startIndex = (currentAlertPage - 1) * alertsPerPage;
    final endIndex = startIndex + alertsPerPage;
    if (startIndex >= lowConfidenceAlerts.length) return [];
    return lowConfidenceAlerts.sublist(
      startIndex,
      endIndex > lowConfidenceAlerts.length ? lowConfidenceAlerts.length : endIndex,
    );
  }

  int get totalAlertPages => (lowConfidenceAlerts.length / alertsPerPage).ceil();

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(error ?? 'Loading AI monitoring data...', style: const TextStyle(color: Colors.grey)),
          if (error != null)
            ElevatedButton(
              onPressed: fetchData,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQueries = reportsData['total_queries'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
        title: const Text(
          'AI & System Monitoring',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading && frequentlyAskedQuestions.isEmpty && lowConfidenceAlerts.isEmpty
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
        child: Column(
          children: [
            // AI Usage Overview Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Usage Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          value: selectedTimeRange,
                          underline: const SizedBox(),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                          items: ['Last Week', 'Last Month', 'Last Year'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedTimeRange = value ?? 'Last Week');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$totalQueries',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Total Queries',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 140,
                              height: 100,
                              child: _buildBarChart(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Usage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: Color(0xFF3B82F6), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: selectedDailyRange,
                                    underline: const SizedBox(),
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                                    items: ['Last Week', 'Last Month', 'Last Year'].map((String value) {
                                      return DropdownMenuItem<String>(value: value, child: Text(value));
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => selectedDailyRange = value ?? 'Last Week');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildDot(0.7, true),
                                _buildDot(0.5, false),
                                _buildDot(0.8, false),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Frequently Asked Questions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: frequentlyAskedQuestions.isNotEmpty
                          ? List.generate(frequentlyAskedQuestions.length, (index) {
                        final faq = frequentlyAskedQuestions[index];
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(faq.question)),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.help, color: Color(0xFF3B82F6), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        faq.question,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            if (index < frequentlyAskedQuestions.length - 1)
                              Divider(height: 1, color: Colors.grey.shade200, indent: 12, endIndent: 12),
                          ],
                        );
                      })
                          : [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No FAQs available', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Managing FAQs...')),
                        );
                      },
                      icon: const Icon(Icons.dashboard, size: 16),
                      label: const Text('Manage FAQs', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Low Confidence Response Alerts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Low-Confidence Response Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lowConfidenceAlerts.length} alerts require attention',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: lowConfidenceAlerts.isNotEmpty
                          ? List.generate(paginatedAlerts.length, (index) {
                        final alert = paginatedAlerts[index];
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.help, color: Color(0xFF3B82F6), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.question,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Confidence Level ${alert.confidenceLevel}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${alert.confidence}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      approveAlert(alert.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Approved!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: const Icon(Icons.check, size: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✏️ Editing...'), duration: Duration(seconds: 1)),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: const Icon(Icons.edit, size: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (index < paginatedAlerts.length - 1)
                              Divider(height: 1, color: Colors.grey.shade200, indent: 12, endIndent: 12),
                          ],
                        );
                      })
                          : [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No alerts pending', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  if (lowConfidenceAlerts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // Alert Pagination
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentAlertPage > 1 ? () => setState(() => currentAlertPage--) : null,
                        ),
                        Text('Page $currentAlertPage of $totalAlertPages', style: const TextStyle(fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentAlertPage < totalAlertPages ? () => setState(() => currentAlertPage++) : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // AI Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.analytics, color: Color(0xFF1E3A8A), size: 32),
                          const SizedBox(height: 8),
                          Text('$totalQueries', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          const Text('Total Queries', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text('${lowConfidenceAlerts.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const Text('Low Confidence', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.help, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          Text('${frequentlyAskedQuestions.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text('FAQs', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
  final List<dynamic> rawList =
      reportsData['daily_usage'] ?? [65, 100, 150, 100, 80, 40, 30];

  final List<int> dailyUsage =
      rawList.map((e) => int.tryParse(e.toString()) ?? 0).toList();

  final maxValue = dailyUsage.isNotEmpty
      ? dailyUsage.reduce((a, b) => a > b ? a : b).toDouble()
      : 100.0;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: dailyUsage.map((value) {
      final height = (value / maxValue) * 80;
      return Container(
        width: 12,
        height: height,
        decoration: BoxDecoration(
          color: Colors.blue.shade400,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }).toList(),
  );
}


  Widget _buildDot(double value, bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}
