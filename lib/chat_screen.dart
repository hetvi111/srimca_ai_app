import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/visitor/visitor_theme.dart';
import 'package:srimca_ai/campus_map_bubble.dart';
import 'package:srimca_ai/markdown_message_view.dart';

/// Authenticated AI chat screen used by students, visitors, and faculty.
/// Follows the StudentChatScreen spec: indigo AppBar, messenger bubbles,
/// welcome message, loading state, automatic campus navigation intent detection,
/// inline OpenStreetMap rendering, and clickable suggestion questions / follow-ups.
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
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const _welcomeText =
      "Hello! I'm SRIMCA AI, your smart college assistant. How can I help you today?";

  static const List<String> _initialSuggestions = [
    "Which courses are offered at SRIMCA?",
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

  Future<void> _sendMessage([String? presetText]) async {
    final question = (presetText ?? _controller.text).trim();
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

      // Extract suggestions or follow_up_questions
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
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth > 600 ? 560.0 : screenWidth * 0.88;

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
              final isLocation = msg['msgType'] == 'location' && msg['location'] != null;
              final suggestions = (msg['suggestions'] as List<dynamic>? ?? [])
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final guidance = msg['guidance'] as String?;

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: isLocation ? (screenWidth > 600 ? 560.0 : screenWidth * 0.92) : maxBubbleWidth,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? chatIndigo : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: isUser ? null : Border.all(color: Colors.grey.shade300, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MarkdownMessageView(
                        text: msg['text'] as String? ?? '',
                        isUser: isUser,
                      ),
                      if (isLocation)
                        CampusMapBubble(
                          location: msg['location'] as Map<String, dynamic>,
                        ),

                      // Personalized Guidance (e.g. Visitor Guidance, Student Tips)
                      if (!isUser && guidance != null && guidance.isNotEmpty) ...[
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
                              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
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

                      // Suggestion Questions (Interactive Clickable Chips)
                      if (!isUser && suggestions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 14, color: chatIndigo),
                            const SizedBox(width: 6),
                            Text(
                              'Suggested Questions:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: chatIndigo.withValues(alpha: 0.9),
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
                                  border: Border.all(color: chatIndigo.withValues(alpha: 0.4)),
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
                                    const Icon(Icons.help_outline_rounded, size: 13, color: chatIndigo),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        suggestionText,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: chatIndigo,
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
              );
            },
          ),
        ),
        _buildQuickSuggestionsBar(),
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
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final q = suggestions[idx];
          return ActionChip(
            avatar: const Icon(Icons.auto_awesome, size: 13, color: chatIndigo),
            label: Text(
              q,
              style: const TextStyle(fontSize: 12, color: chatIndigo, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: chatIndigo.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _sendMessage(q),
          );
        },
      ),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : () => _sendMessage(),
            icon: Icon(Icons.send, color: _isLoading ? Colors.grey : chatIndigo),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}
