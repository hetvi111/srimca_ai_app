import 'package:flutter/material.dart';
import 'package:srimca_ai/static_data.dart';

class FacultyAiAssistantPage extends StatefulWidget {
  const FacultyAiAssistantPage({super.key});

  @override
  State<FacultyAiAssistantPage> createState() =>
      _FacultyAiAssistantPageState();
}

class _FacultyAiAssistantPageState
    extends State<FacultyAiAssistantPage> {

  final TextEditingController controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      // Mock load FAQs (no backend)
      final faqs = StaticData.faqs;
      setState(() {
        messages = faqs.map((faq) => {
          "role": "ai",
          "text": "${faq['question']}\n\nAnswer: ${faq.containsKey('answer') ? faq['answer'] : 'Pending...'}"
        }).toList().cast<Map<String, String>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": controller.text});
      isSending = true;
    });

    try {
      // Mock add FAQ (no backend)
      setState(() {
        messages.add({
          "role": "ai",
          "text": "Query received and processed by AI system."
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }

    controller.clear();
    setState(() => isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty AI Assistant"),
        backgroundColor: const Color(0xFF1F4E8C),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          Expanded(
            child: messages.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF1F4E8C)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ask AI...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: isSending
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send, color: Color(0xFF1F4E8C)),
                  onPressed: isSending ? null : sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
