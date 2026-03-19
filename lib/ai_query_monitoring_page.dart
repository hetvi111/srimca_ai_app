import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

class AiQueryMonitoringPage extends StatefulWidget {
  const AiQueryMonitoringPage({super.key});

  @override
  State<AiQueryMonitoringPage> createState() => _AiQueryMonitoringPageState();
}

class _AiQueryMonitoringPageState extends State<AiQueryMonitoringPage> {
  List<Map<String, dynamic>> queries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    final data = await ApiService.getAiMonitoringData(period: 'all', limit: 200);
    final loadedQueries = (data['queries'] as List<dynamic>).cast<Map<String, dynamic>>();
    setState(() {
      queries = loadedQueries;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Query Monitoring"),
        backgroundColor: const Color(0xFF1F4E8C),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : queries.isEmpty
              ? const Center(child: Text('No queries yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: queries.length,
                  itemBuilder: (context, index) {
                    final item = queries[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(item["student"]?.toString() ?? "Unknown User"),
                        subtitle: Text(item["question"]?.toString() ?? ""),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              "AI Answer:\n${item["answer"]?.toString() ?? ''}",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
