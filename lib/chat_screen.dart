import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/visitor_theme.dart';

/// Authenticated AI chat screen used by students (and optionally visitors).
/// Follows the StudentChatScreen spec: indigo AppBar, messenger bubbles,
/// welcome message, loading state, and POST /api/ai/chat via ApiService.
class ChatScreen extends StatefulWidget {
  final String? token;
  final String? userId;

  /// When true, hides the AppBar (parent scaffold provides navigation).
  final bool embedded;

  const ChatScreen({
    super.key,
    this.token,
    this.userId,
    this.embedded = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const _welcomeText =
      "Hello! I'm SRIMCA AI, your smart college assistant. How can I help you today?";

  @override
  void initState() {
    super.initState();
    _messages.add({'type': 'bot', 'text': _welcomeText});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'type': 'user', 'text': question});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final answer = await ApiService.askAI(question);
      if (!mounted) return;
      setState(() {
        _messages.add({'type': 'bot', 'text': answer});
        _isLoading = false;
      });

      final userId = widget.userId;
      if (userId != null && userId.isNotEmpty && userId != 'guest') {
        ApiService.saveChatMessage(
          userId: userId,
          question: question,
          answer: answer,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'type': 'bot', 'text': 'Error: $e'});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    final chatBody = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isLoading && index == _messages.length) {
                return _buildLoadingIndicator(maxBubbleWidth);
              }
              final msg = _messages[index];
              final isUser = msg['type'] == 'user';
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  decoration: BoxDecoration(
                    color: isUser ? chatIndigo : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildInputArea(),
      ],
    );

    if (widget.embedded) {
      return chatBody;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: chatIndigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: chatBody,
    );
  }

  Widget _buildLoadingIndicator(double maxWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('AI is thinking...', style: TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Ask something about the college...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: Icon(Icons.send, color: _isLoading ? Colors.grey : chatIndigo),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}
