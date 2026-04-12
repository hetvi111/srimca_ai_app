import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class ChatScreen extends StatefulWidget {
  final String? userId;
  
  const ChatScreen({super.key, this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool isSending = false;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
    _typingController.repeat();
    _addWelcomeMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _typingController.dispose();
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      messages.add({
        "text": "Hello! I'm SAI, your SRIMCA AI Assistant. I'm here to help you with any academic or college-related questions. How can I assist you today?",
        "isUser": false,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    if (isSending) return;

    final userMessage = messageController.text.trim();
    final timestamp = DateTime.now().toIso8601String();

    setState(() {
      messages.add({
        "text": userMessage,
        "isUser": true,
        "timestamp": timestamp,
      });
      // Add typing indicator
      messages.add({
        "isTyping": true,
        "isUser": false,
      });
      isSending = true;
    });

    messageController.clear();
    _scrollToBottom();

    String? response;
    try {
      response = await _getAIResponse(userMessage);
    } catch (e) {
      response = "Sorry, I encountered an error. Please try again. ($e)";
    }

    if (mounted) {
      setState(() {
        // Remove typing
        if (messages.isNotEmpty && messages.last['isTyping'] == true) {
          messages.removeLast();
        }
        // Add real response
        messages.add({
          "text": response,
          "isUser": false,
          "timestamp": DateTime.now().toIso8601String(),
        });
        isSending = false;
      });
      _scrollToBottom();

      // Save to chat history
      if (widget.userId != null && response != null) {
        await ApiService.saveChatMessage(
          userId: widget.userId!,
          question: userMessage,
          answer: response,
        );
      }
    }
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
    
    if (lowerQuestion.contains('exam') || lowerQuestion.contains('schedule')) {
      return "The mid-term examination schedule will be announced soon. Please check the notice board regularly for updates.";
    } else if (lowerQuestion.contains('assignment') || lowerQuestion.contains('submit')) {
      return "To submit an assignment, log in to the student portal, go to 'Assignments' section, select the relevant assignment, and upload your work before the deadline.";
    } else if (lowerQuestion.contains('syllabus') || lowerQuestion.contains('course')) {
      return "The course syllabus typically includes: Data Structures, Database Management, Operating Systems, Computer Networks, Web Technologies, and AI/ML fundamentals. You can find detailed syllabus in your course handbook.";
    } else if (lowerQuestion.contains('fee') || lowerQuestion.contains('payment')) {
      return "For fee-related queries, please contact the accounts department or visit the administration office. You can also check your fee status through the student portal.";
    } else if (lowerQuestion.contains('library') || lowerQuestion.contains('book')) {
      return "The library is open from 9:00 AM to 6:00 PM on weekdays. You can issue books using your student ID card. Maximum 5 books can be issued at a time.";
    } else {
      return "Thank you for your question! Please check the notice board or contact your faculty advisor.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F9FF), Color(0xFFE8EEF7), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // TOP BAR (unchanged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: navyBlue,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "SAI",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
                      ],
                    ),
                  ],
                ),
              ),
              // ... greeting and quick actions unchanged ...
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      "Hello 👋",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navyBlue),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text("Online", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("How can I help you today?", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _actionChip(Icons.quiz, "Exam Info"),
                    _actionChip(Icons.assignment, "Assignments"),
                    _actionChip(Icons.book, "Syllabus"),
                    _actionChip(Icons.schedule, "Schedule"),
                    _actionChip(Icons.help, "Help"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: lightGrey, borderRadius: BorderRadius.circular(25)),
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(hintText: "Ask me anything...", border: InputBorder.none),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(color: accentBlue, shape: BoxShape.circle),
                      child: IconButton(
                        icon: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
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
    final isUser = msg["isUser"] as bool?;
    final isTyping = msg["isTyping"] as bool? ?? false;

    if (isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.smart_toy, size: 14, color: accentBlue),
                    ),
                    const SizedBox(width: 6),
                    const Text("SAI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentBlue)),
                  ],
                ),
              ),
              _typingIndicator(),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isUser! ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? accentBlue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smart_toy, size: 14, color: accentBlue),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "SAI",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg["text"],
              style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _typingAnimation,
          builder: (context, child) {
            return Column(
              children: List.generate(3, (index) => Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                transform: Matrix4.identity()..translate(0, _typingAnimation.value * 20 * (index == 0 ? 1 : index == 1 ? 0.5 : -0.5)),
              )),
            );
          },
        ),
        const SizedBox(width: 8),
        Text("Typing...", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ],
    );
  }

  Widget _actionChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: Colors.white,
        avatar: Icon(icon, size: 16, color: accentBlue),
        label: Text(text, style: const TextStyle(fontSize: 12, color: navyBlue)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        onPressed: () {
          messageController.text = "Tell me about $text";
          _scrollToBottom();
        },
      ),
    );
  }
}

