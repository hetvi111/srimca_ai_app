import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= AI MONITORING PAGE =================
class AIMonitoringPage extends StatefulWidget {
  const AIMonitoringPage({super.key});

  @override
  State<AIMonitoringPage> createState() => _AIMonitoringPageState();
}

class _AIMonitoringPageState extends State<AIMonitoringPage> {
  List<Map<String, dynamic>> queries = [];
  bool isLoading = true;
  String selectedFilter = "All";
  int totalQueries = 0;
  int todayQueries = 0;
  String avgResponse = "<2s";

  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    try {
      String period = 'all';
      if (selectedFilter == 'Today') {
        period = 'today';
      } else if (selectedFilter == 'This Week') {
        period = 'week';
      }

      final data = await ApiService.getAiMonitoringData(period: period, limit: 200);
      final loadedQueries = (data['queries'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final stats = data['stats'] as Map<String, dynamic>;

      setState(() {
        queries = loadedQueries;
        totalQueries = (stats['total_queries'] as num?)?.toInt() ?? loadedQueries.length;
        todayQueries = (stats['today_queries'] as num?)?.toInt() ?? 0;
        avgResponse = stats['avg_response']?.toString() ?? '<2s';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        queries = [];
        totalQueries = 0;
        todayQueries = 0;
        avgResponse = '<2s';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredQueries {
    if (selectedFilter == "All" || selectedFilter == "Today" || selectedFilter == "This Week") {
      return queries;
    }
    return queries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Monitoring", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
                isLoading = true;
              });
              _loadQueries();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All Queries")),
              const PopupMenuItem(value: "Today", child: Text("Today")),
              const PopupMenuItem(value: "This Week", child: Text("This Week")),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard("Total Queries", totalQueries.toString(), Icons.chat, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard("Today", todayQueries.toString(), Icons.today, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard("Avg Response", avgResponse, Icons.timer, Colors.orange),
                    ],
                  ),
                ),
                // Query List
                Expanded(
                  child: filteredQueries.isEmpty
                      ? const Center(child: Text('No AI queries found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredQueries.length,
                          itemBuilder: (context, index) {
                            final query = filteredQueries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                title: Text(query["student"]?.toString() ?? "Unknown User"),
                                subtitle: Text(query["question"]?.toString() ?? ""),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Question: ${query["question"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text("Answer: ${query["answer"]}"),
                                        const SizedBox(height: 8),
                                        Text("Time: ${query["timestamp"] ?? ''}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
