import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/visitor/visitor_theme.dart';
import 'package:srimca_ai/campus_map_bubble.dart';
import 'package:srimca_ai/markdown_message_view.dart';

/// Visitor AI Assistant chat with suggested questions panel (web layout).
class VisitorChatPage extends StatefulWidget {
  final String? userId;

  const VisitorChatPage({super.key, this.userId});

  @override
  State<VisitorChatPage> createState() => _VisitorChatPageState();
}

class _VisitorChatPageState extends State<VisitorChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const _suggestedQuestions = [
    'Where is the library?',
    'Where is the computer lab?',
    'Where is the canteen?',
    'What courses are offered?',
    'What is the fee structure?',
    'How do I schedule a campus visit?',
    'Where is SRIMCA located?',
    'What facilities are available on campus?',
  ];

  static const _welcomeText =
      "Hello! I'm SRIMCA AI, your smart college assistant. How can I help you today?";

  static const List<String> _initialSuggestions = [
    "What courses are offered at SRIMCA?",
    "Where is the library located?",
    "What is the fee structure for BCA/MCA?",
    "How can I apply for admission?",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'type': 'bot',
      'text': _welcomeText,
      'msgType': 'text',
      'location': null,
      'suggestions': _initialSuggestions,
      'guidance': null,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
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

  Future<void> _sendMessage([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'type': 'user',
        'text': question,
        'msgType': 'text',
        'location': null,
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await ApiService.askAIChat(question);
      if (!mounted) return;

      final answer = result['answer'] as String? ?? "I couldn't generate a response.";
      final msgType = result['type'] as String? ?? 'text';
      final location = result['location'] as Map<String, dynamic>?;

      final suggestions = (result['suggestions'] as List<dynamic>? ??
              result['follow_up_questions'] as List<dynamic>?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ?? <String>[];

      final guidance = (result['personalized_guidance'] as String?)?.trim();

      setState(() {
        _messages.add({
          'type': 'bot',
          'text': answer,
          'msgType': msgType,
          'location': location,
          'suggestions': suggestions,
          'guidance': guidance,
        });
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
        _messages.add({
          'type': 'bot',
          'text': 'Error: $e',
          'msgType': 'text',
          'location': null,
          'suggestions': <String>[],
          'guidance': null,
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: visitorBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildChatArea()),
          if (isWide) _buildSidePanel(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: visitorNavy,
                ),
              ),
              Text(
                'Ask anything about SRIMCA',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isLoading && index == _messages.length) {
                return _buildBotBubble(null, loading: true);
              }
              final msg = _messages[index];
              final isUser = msg['type'] == 'user';
              return isUser
                  ? _buildUserBubble(msg['text'] as String? ?? '')
                  : _buildBotBubble(
                      msg['text'] as String?,
                      location: msg['location'] as Map<String, dynamic>?,
                      suggestions: (msg['suggestions'] as List<dynamic>? ?? [])
                          .map((e) => e.toString())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      guidance: msg['guidance'] as String?,
                    );
            },
          ),
        ),
        _buildQuickSuggestionsBar(),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBotBubble(
    String? text, {
    bool loading = false,
    Map<String, dynamic>? location,
    List<String> suggestions = const [],
    String? guidance,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = location != null
        ? (screenWidth > 700 ? 560.0 : screenWidth * 0.85)
        : (screenWidth > 900 ? 500.0 : screenWidth * 0.65);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: visitorPrimary.withValues(alpha: 0.15),
            child: const Icon(Icons.smart_toy, size: 18, color: visitorPrimary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: loading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('AI is thinking...'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarkdownMessageView(
                          text: text ?? '',
                        ),
                        if (location != null)
                          CampusMapBubble(location: location),

                        // Guidance box
                        if (guidance != null && guidance.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded,
                                    size: 16, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MarkdownMessageView(
                                    text: guidance,
                                    baseStyle: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF1E3A8A),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Interactive Clickable Suggestion Chips
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 14, color: visitorPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Suggested Questions:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: visitorPrimary.withValues(alpha: 0.9),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: suggestions.map((suggestionText) {
                              return InkWell(
                                onTap: _isLoading ? null : () => _sendMessage(suggestionText),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: visitorPrimary.withValues(alpha: 0.35)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.help_outline_rounded, size: 13, color: visitorPrimary),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          suggestionText,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: visitorPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal quick-scroll suggestion bar right above the input box
  Widget _buildQuickSuggestionsBar() {
    if (_isLoading || _messages.isEmpty) return const SizedBox.shrink();
    final lastMsg = _messages.last;
    if (lastMsg['type'] != 'bot') return const SizedBox.shrink();

    final suggestions = (lastMsg['suggestions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final q = suggestions[idx];
          return ActionChip(
            avatar: const Icon(Icons.auto_awesome, size: 13, color: visitorPrimary),
            label: Text(
              q,
              style: const TextStyle(fontSize: 12, color: visitorPrimary, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: visitorPrimary.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _sendMessage(q),
          );
        },
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.55,
        ),
        decoration: BoxDecoration(
          color: visitorPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: visitorBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : () {},
            icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
          ),
          IconButton(
            onPressed: _isLoading ? null : () {},
            icon: Icon(Icons.mic, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _sendMessage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: visitorPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 300,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Questions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _suggestedQuestions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final q = _suggestedQuestions[index];
                return InkWell(
                  onTap: _isLoading ? null : () => _sendMessage(q),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: visitorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(q, style: const TextStyle(fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chat History',
                style: TextStyle(fontWeight: FontWeight.bold, color: visitorNavy),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          _historyTile('Admission inquiry'),
          _historyTile('Campus visit timing'),
          _historyTile('Course details'),
        ],
      ),
    );
  }

  Widget _historyTile(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
