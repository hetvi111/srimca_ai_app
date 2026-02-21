import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class StudentChatHistoryPage extends StatefulWidget {
  final String userId;
  
  const StudentChatHistoryPage({
    super.key,
    required this.userId,
  });

  @override
  State<StudentChatHistoryPage> createState() => _StudentChatHistoryPageState();
}

class _StudentChatHistoryPageState extends State<StudentChatHistoryPage> {
  List<dynamic> chatHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      // Fetch chat history from backend
      final history = await ApiService.getChatHistory(widget.userId);
      if (mounted) {
        setState(() {
          chatHistory = history;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
      // Show demo data when API fails
      if (mounted) {
        setState(() {
          chatHistory = _getDemoChatHistory();
          isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getDemoChatHistory() {
    return [
      {
        'id': '1',
        'question': 'What is artificial intelligence?',
        'answer': 'Artificial Intelligence (AI) is a branch of computer science that aims to create intelligent machines that can perform tasks that typically require human intelligence.',
        'timestamp': '2024-02-20 10:30:00',
      },
      {
        'id': '2',
        'question': 'Tell me about machine learning',
        'answer': 'Machine Learning is a subset of AI that enables systems to automatically learn and improve from experience without being explicitly programmed.',
        'timestamp': '2024-02-19 14:15:00',
      },
      {
        'id': '3',
        'question': 'What are the exam dates?',
        'answer': 'Mid-term exams are scheduled to begin from March 1st, 2024. The detailed schedule will be posted on the notice board.',
        'timestamp': '2024-02-18 09:00:00',
      },
      {
        'id': '4',
        'question': 'How to submit assignment?',
        'answer': 'You can submit assignments through the student portal. Go to Assignments > Submit Assignment > Upload your file.',
        'timestamp': '2024-02-17 16:45:00',
      },
      {
        'id': '5',
        'question': 'What is the course syllabus?',
        'answer': 'The course syllabus includes: Introduction to Programming, Data Structures, Database Management, Web Development, and AI/ML fundamentals.',
        'timestamp': '2024-02-16 11:20:00',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chat History"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = chatHistory[index];
                      return _buildChatCard(chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Chat History",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your chat conversations will appear here",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final question = chat['question'] ?? '';
    final answer = chat['answer'] ?? '';
    final timestamp = chat['timestamp'] ?? '';
    
    // Format timestamp
    String formattedDate = '';
    try {
      if (timestamp.isNotEmpty) {
        final dateTime = DateTime.parse(timestamp);
        formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      formattedDate = timestamp;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "You asked:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Question
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: navyBlue,
              ),
            ),
          ),
          
          const Divider(height: 1, color: Colors.grey),
          
          // Answer Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: accentBlue, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  "SAI Response:",
                  style: TextStyle(
                    color: accentBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Answer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
