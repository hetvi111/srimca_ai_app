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

  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    try {
      // Mock data
      setState(() {
        queries = [
          {"student": "John Doe", "question": "What is Python?", "answer": "Python is a high-level programming language...", "timestamp": "2024-01-15 10:30"},
          {"student": "Jane Smith", "question": "How to implement recursion?", "answer": "Recursion is a method where...", "timestamp": "2024-01-15 11:45"},
          {"student": "Bob Wilson", "question": "What is OOP?", "answer": "Object-Oriented Programming is...", "timestamp": "2024-01-15 14:20"},
          {"student": "Alice Brown", "question": "Explain database normalization", "answer": "Database normalization is...", "timestamp": "2024-01-16 09:15"},
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        queries = [];
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredQueries {
    if (selectedFilter == "All") return queries;
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
              });
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
                      _buildStatCard("Total Queries", queries.length.toString(), Icons.chat, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard("Today", "12", Icons.today, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard("Avg Response", "<2s", Icons.timer, Colors.orange),
                    ],
                  ),
                ),
                // Query List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredQueries.length,
                    itemBuilder: (context, index) {
                      final query = filteredQueries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(query["student"] ?? ""),
                          subtitle: Text(query["question"] ?? ""),
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
                                  Text("Time: ${query["timestamp"]}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
