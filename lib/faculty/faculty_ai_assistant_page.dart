import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/markdown_message_view.dart';

class FacultyAiAssistantPage extends StatefulWidget {
  const FacultyAiAssistantPage({super.key});

  @override
  State<FacultyAiAssistantPage> createState() =>
      _FacultyAiAssistantPageState();
}

class _FacultyAiAssistantPageState
    extends State<FacultyAiAssistantPage> {

  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final user = await AuthService.getUser();
      final userId = user?['_id']?.toString() ?? '';
      final history = userId.isNotEmpty
          ? await ApiService.getChatHistory(userId)
          : <Map<String, dynamic>>[];

      setState(() {
        messages = history.expand((item) => [
          {
            "role": "user",
            "text": (item['question'] ?? '').toString(),
          },
          {
            "role": "ai",
            "text": (item['answer'] ?? '').toString(),
            "suggestions": <String>[],
            "guidance": null,
          },
        ]).toList().cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage([String? presetText]) async {
    final question = (presetText ?? controller.text).trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": question});
      isSending = true;
    });

    try {
      final result = await ApiService.askAIDetailed(question);
      final answer = result['answer'] as String? ?? "I couldn't generate a response.";
      final suggestions = (result['suggestions'] as List<dynamic>? ??
              result['follow_up_questions'] as List<dynamic>?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ?? <String>[];
      final guidance = (result['personalized_guidance'] as String?)?.trim();

      final user = await AuthService.getUser();
      final userId = user?['_id']?.toString() ?? '';

      if (userId.isNotEmpty) {
        await ApiService.saveChatMessage(
          userId: userId,
          question: question,
          answer: answer,
        );
      }

      setState(() {
        messages.add({
          "role": "ai",
          "text": answer,
          "suggestions": suggestions,
          "guidance": guidance,
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
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
                final suggestions = (msg["suggestions"] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
                    .toList();
                final guidance = msg["guidance"] as String?;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF1F4E8C)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarkdownMessageView(
                          text: msg["text"]?.toString() ?? '',
                          isUser: isUser,
                        ),
                        if (!isUser && guidance != null && guidance.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          MarkdownMessageView(
                            text: guidance,
                            baseStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1F4E8C),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (!isUser && suggestions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                          const Text(
                            'Follow-up Questions:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F4E8C)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: suggestions.map((s) => ActionChip(
                              label: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF1F4E8C))),
                              backgroundColor: Colors.white,
                              onPressed: isSending ? null : () => sendMessage(s),
                            )).toList(),
                          ),
                        ],
                      ],
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
