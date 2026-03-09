import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/student_chat_history_page.dart';
import 'package:srimca_ai/visitor_history_page.dart';
import 'dart:math';

const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class ChatScreen extends StatefulWidget {
  final String? userId;
  final String userType;

  const ChatScreen({super.key, this.userId, this.userType = 'student'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();

  bool isSending = false;
  bool _isTyping = false;
  String _lastFallback = "";

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      messages.add({
        "text":
            "Hello! I'm SAI, your SRIMCA AI Assistant. I'm here to help you with any academic or college-related questions. How can I assist you today?",
        "isUser": false,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final userMessage = messageController.text;
    final timestamp = DateTime.now().toIso8601String();

    setState(() {
      messages.add({
        "text": userMessage,
        "isUser": true,
        "timestamp": timestamp,
      });
      isSending = true;
      _isTyping = true;
    });

    messageController.clear();
    _scrollToBottom();

    try {
      final response = await _getAIResponse(userMessage);

      if (mounted) {
        setState(() {
          messages.add({
            "text": response,
            "isUser": false,
            "timestamp": DateTime.now().toIso8601String(),
          });
          _isTyping = false;
        });

        if (widget.userId != null) {
          await ApiService.saveChatMessage(
            userId: widget.userId!,
            question: userMessage,
            answer: response,
          );
        }
      }
    } catch (e) {
      setState(() {
        messages.add({
          "text":
              "I apologize, but I'm having trouble processing your request right now.",
          "isUser": false,
          "timestamp": DateTime.now().toIso8601String(),
        });
        _isTyping = false;
      });
    }

    if (mounted) {
      setState(() => isSending = false);
    }

    _scrollToBottom();
  }

  Future<String> _getAIResponse(String question) async {
    try {
      final response = await ApiService.askAI(question);
      return response;
    } catch (e) {
      return _getFallbackResponse(question);
    }
  }

  String _getFallbackResponse(String question) {
    final lowerQuestion = question.toLowerCase();

    Map<String, List<String>> responses = {
      "exam": [
        "The mid-term examination schedule will be announced soon.",
        "Exams usually begin after each unit is completed.",
        "Please check the SRIMCA notice board for exam updates."
      ],
      "assignment": [
        "Assignments can be submitted through the student portal.",
        "Please upload your assignment before the deadline.",
        "Faculty may also accept assignments through LMS."
      ],
      "syllabus": [
        "The syllabus includes Data Structures, DBMS, OS, Networks and AI.",
        "Detailed syllabus is available in your course handbook.",
        "You can check the SRIMCA website for updated syllabus."
      ],
      "fee": [
        "For fee details please contact the accounts department.",
        "You can also check your fee status in the student portal.",
        "Fee payment deadlines are announced every semester."
      ],
      "library": [
        "The SRIMCA library is open from 9:00 AM to 6:00 PM.",
        "Students can issue books using their ID card.",
        "The library contains academic books and journals."
      ],
      "result": [
        "Results are usually declared within two weeks after exams.",
        "You can check your results on the university website.",
        "Results will be available using your enrollment number."
      ]
    };

    for (var key in responses.keys) {
      if (lowerQuestion.contains(key)) {
        List<String> options = responses[key]!;

        String reply = options[_random.nextInt(options.length)];

        while (reply == _lastFallback && options.length > 1) {
          reply = options[_random.nextInt(options.length)];
        }

        _lastFallback = reply;
        return reply;
      }
    }

    List<String> defaultReplies = [
      "I'm here to help with SRIMCA related questions.",
      "Please ask about SRIMCA courses, exams, or facilities.",
      "I'm still learning. Try asking about SRIMCA programs.",
      "You can ask about syllabus, faculty, or exam schedule."
    ];

    String reply = defaultReplies[_random.nextInt(defaultReplies.length)];

    while (reply == _lastFallback && defaultReplies.length > 1) {
      reply = defaultReplies[_random.nextInt(defaultReplies.length)];
    }

    _lastFallback = reply;

    return reply;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F9FF),
              Color(0xFFE8EEF7),
              Color(0xFFE3F2FD),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              /// TOP BAR
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: navyBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "SAI",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white),
                      onPressed: () {},
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// CHAT LIST
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              /// TYPING INDICATOR
              if (_isTyping)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.smart_toy, size: 18, color: accentBlue),
                      SizedBox(width: 6),
                      Text(
                        "SAI is typing...",
                        style: TextStyle(
                          color: accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              /// INPUT BAR
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: lightGrey,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: "Ask me anything...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: isSending
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2)
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: isSending ? null : sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg["isUser"] as bool;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? accentBlue : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          msg["text"],
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}