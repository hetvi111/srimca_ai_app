import 'package:flutter/material.dart';
import 'package:srimca_ai/static_data.dart';

class AiQueryMonitoringPage extends StatefulWidget {
  const AiQueryMonitoringPage({super.key});

  @override
  State<AiQueryMonitoringPage> createState() => _AiQueryMonitoringPageState();
}

class _AiQueryMonitoringPageState extends State<AiQueryMonitoringPage> {
  List<Map<String, String>> queries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    // Mock load queries (no backend)
    await Future.delayed(const Duration(milliseconds: 500));
    final faqs = StaticData.faqs;
    setState(() {
      queries = faqs.map((faq) => {
        "student": "Student User",
        "question": faq['question'] ?? 'N/A',
        "answer": faq.containsKey('answer') ? faq['answer'] : 'Answer pending...'
      }).toList().cast<Map<String, String>>();
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
              title: Text(item["student"]!),
              subtitle: Text(item["question"]!),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "AI Answer:\n${item["answer"]}",
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
