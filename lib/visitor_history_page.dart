import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class VisitorHistoryPage extends StatefulWidget {
  final String visitorId;
  
  const VisitorHistoryPage({
    super.key,
    required this.visitorId,
  });

  @override
  State<VisitorHistoryPage> createState() => _VisitorHistoryPageState();
}

class _VisitorHistoryPageState extends State<VisitorHistoryPage> {
  List<dynamic> chatHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      // Fetch chat history from backend for visitor
      final history = await ApiService.getChatHistory(widget.visitorId);
      if (mounted) {
        setState(() {
          chatHistory = history;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading visitor chat history: $e');
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
        'question': 'What are the college admission requirements?',
        'answer': 'For admission to SRIMCA, you need to have completed 10+2 with Science stream (Physics, Chemistry, Mathematics) with minimum 50% marks. You also need to appear for the college entrance exam or provide valid JEE/GATE scores.',
        'timestamp': '2024-02-20 10:30:00',
      },
      {
        'id': '2',
        'question': 'What courses are offered?',
        'answer': 'SRIMCA offers various courses including: B.Tech in Computer Science, Information Technology, Mechanical Engineering, Civil Engineering, and MBA programs. We also offer M.Tech and Ph.D. programs.',
        'timestamp': '2024-02-19 14:15:00',
      },
      {
        'id': '3',
        'question': 'What is the college fee structure?',
        'answer': 'The fee structure varies by course. For B.Tech, the annual fee is approximately Rs. 1,50,000 - 2,00,000. For MBA, it is around Rs. 1,00,000 - 1,50,000 per year. Additional fees include hostel, transport, and examination fees.',
        'timestamp': '2024-02-18 09:00:00',
      },
      {
        'id': '4',
        'question': 'Is there hostel facility available?',
        'answer': 'Yes, SRIMCA provides separate hostels for boys and girls with modern amenities. The hostel fees are approximately Rs. 60,000 - 80,000 per year including food. Rooms are available on single, double, and triple sharing basis.',
        'timestamp': '2024-02-17 16:45:00',
      },
      {
        'id': '5',
        'question': 'What are the placement opportunities?',
        'answer': 'SRIMCA has an excellent placement record with top companies like TCS, Infosys, Wipro, Google, Microsoft visiting the campus. The placement percentage is over 90% with average salary packages of 4-6 LPA for B.Tech students.',
        'timestamp': '2024-02-16 11:20:00',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Visitor Chat History"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            Icons.history,
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
              color: navyBlue,
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
