import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/visitor_chat_page.dart';
import 'package:srimca_ai/visitor_portal_layout.dart';
import 'package:srimca_ai/visitor_profile_page.dart';
import 'package:srimca_ai/visitor_theme.dart';
import 'package:srimca_ai/visitor_qr_page.dart';

class VisitorHomePage extends StatefulWidget {
  final String token;
  final String userId;
  final String? userName;

  const VisitorHomePage({
    super.key,
    required this.token,
    required this.userId,
    this.userName,
  });

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  int _selectedIndex = 0;
  String _displayName = 'Visitor';
  String _token = '';
  Map<String, dynamic> _profile = {};
  List<dynamic> _visitHistory = [];
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName ?? 'Visitor';
    _token = widget.token;
    _initAuth();
  }

  Future<void> _initAuth() async {
    if (_token == 'visitor' || _token == 'guest') {
      final savedToken = await AuthService.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
      }
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.userId == 'guest' || widget.userId.isEmpty) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final profile = await ApiService.getProfile(_token, widget.userId);
      final history = await ApiService.getHistory(_token, widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile ?? {};
        _visitHistory = history;
        _displayName = (_profile['name'] as String?) ?? _displayName;
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _onNavTap(int index) {
    if (index == 6) {
      _logout();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await AuthService.clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return VisitorPortalLayout(
      userName: _displayName,
      selectedIndex: _selectedIndex,
      onNavTap: _onNavTap,
      notificationCount: 3,
      child: _buildPage(),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return _buildMyVisitsPage();
      case 2:
        return VisitorChatPage(userId: widget.userId);
      case 3:
        return _buildNotificationsPage();
      case 4:
        return VisitorProfilePage(
          token: _token,
          userId: widget.userId,
          embedded: true,
        );
      case 5:
        return _buildContactPage();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 28),
          const Text(
            'Quick Suggestions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: crossCount == 1 ? 2.2 : 0.85,
                children: [
                  _suggestionCard(
                    'Ask AI Assistant',
                    'Get instant answers about courses, admissions, and campus life.',
                    Icons.smart_toy,
                    const Color(0xFFE3F2FD),
                    visitorPrimary,
                    'Start Chat >',
                    () => setState(() => _selectedIndex = 2),
                  ),
                  _suggestionCard(
                    'About SRIMCA',
                    'Learn about our programs, faculty, and campus facilities.',
                    Icons.info_outline,
                    const Color(0xFFE8F5E9),
                    Colors.green.shade700,
                    'Learn More >',
                    () {},
                  ),
                  _suggestionCard(
                    'Upcoming Events',
                    'Stay updated with college events, seminars, and workshops.',
                    Icons.event,
                    const Color(0xFFF3E5F5),
                    Colors.purple.shade700,
                    'View Events >',
                    () {},
                  ),
                  _suggestionCard(
                    'Contact Us',
                    'Reach out to our team for admissions and general inquiries.',
                    Icons.phone,
                    const Color(0xFFFFF3E0),
                    Colors.orange.shade800,
                    'Contact Now >',
                    () => setState(() => _selectedIndex = 5),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _buildHelpBanner(),
          if (!_loadingProfile && _visitHistory.isNotEmpty) ...[
            const SizedBox(height: 28),
            _buildUpcomingVisitCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_displayName! 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: visitorNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We're happy to have you here at SRIMCA. How can we assist you today?",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [visitorPrimary.withValues(alpha: 0.8), visitorPrimary],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.apartment,
                size: 64,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 700;
                  if (isStacked) {
                    return Column(
                      children: [
                        _actionOverlayCard(
                          Icons.calendar_month,
                          'Plan Your Visit',
                          'Register and schedule your visit.',
                          () => Navigator.pushNamed(context, '/register'),
                        ),
                        const SizedBox(height: 12),
                        _actionOverlayCard(
                          Icons.chat_bubble_outline,
                          'Get Information',
                          'Ask our AI Assistant any query.',
                          () => setState(() => _selectedIndex = 2),
                        ),
                        const SizedBox(height: 12),
                        _actionOverlayCard(
                          Icons.description_outlined,
                          'Track Status',
                          'Check your visit request status.',
                          () => setState(() => _selectedIndex = 1),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _actionOverlayCard(
                          Icons.calendar_month,
                          'Plan Your Visit',
                          'Register and schedule your visit.',
                          () => Navigator.pushNamed(context, '/register'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionOverlayCard(
                          Icons.chat_bubble_outline,
                          'Get Information',
                          'Ask our AI Assistant any query.',
                          () => setState(() => _selectedIndex = 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionOverlayCard(
                          Icons.description_outlined,
                          'Track Status',
                          'Check your visit request status.',
                          () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _actionOverlayCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: visitorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: visitorPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: visitorNavy,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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

  Widget _suggestionCard(
    String title,
    String desc,
    IconData icon,
    Color bg,
    Color accent,
    String buttonLabel,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(buttonLabel, style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 700;
          return stacked
              ? Column(
                  children: [
                    const Icon(Icons.waving_hand, size: 48, color: visitorPrimary),
                    const SizedBox(height: 12),
                    const Text(
                      'Need Help? Use our AI Assistant to get instant support or contact our team for more information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: visitorNavy, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 2),
                      icon: const Icon(Icons.chat),
                      label: const Text('Ask AI Assistant >'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: visitorPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.waving_hand, size: 48, color: visitorPrimary),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Need Help? Use our AI Assistant to get instant support or contact our team for more information.',
                        style: TextStyle(color: visitorNavy, height: 1.4),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 2),
                      icon: const Icon(Icons.chat),
                      label: const Text('Ask AI Assistant >'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: visitorPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildUpcomingVisitCard() {
    final latest = _visitHistory.isNotEmpty ? _visitHistory.first : null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Visit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile['department']?.toString() ??
                          'Department of MCA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Purpose: ${_profile['purpose'] ?? 'Campus Visit'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (latest != null)
                      Text(
                        'Check-in: ${latest['check_in'] ?? 'Pending'}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _profile['status']?.toString() ?? 'Approved',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisitorQRPage(
                        token: _token,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: visitorPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Pass'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyVisitsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Visits',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track all your visit requests and history.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          if (_visitHistory.isEmpty)
            _emptyState('No visits yet', 'Plan your first campus visit today.')
          else
            ..._visitHistory.map((item) => _visitListTile(item)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _visitHistory.length;
    final approved = _visitHistory
        .where((v) => (v['status']?.toString().toLowerCase() ?? '') == 'approved')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _statCard('Total Visits', '$total', Icons.event, visitorPrimary),
            _statCard('Pending', '${total - approved}', Icons.pending, Colors.orange),
            _statCard('Approved', '$approved', Icons.check_circle, Colors.green),
            _statCard('Notifications', '3', Icons.notifications, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _visitListTile(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: visitorPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['check_in']?.toString() ?? 'Visit',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  item['status']?.toString() ?? 'Pending',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VisitorQRPage(
                    token: _token,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: const Text('View Pass'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    final notifications = [
      ('Visit Approved', 'Your campus visit has been approved.', '2h ago'),
      ('Welcome to SRIMCA', 'Explore AI Assistant and plan your visit.', '1d ago'),
      ('Reminder', 'Bring a valid ID for your scheduled visit.', '3d ago'),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: visitorNavy,
          ),
        ),
        const SizedBox(height: 16),
        ...notifications.map(
          (n) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: visitorPrimary.withValues(alpha: 0.1),
                child: const Icon(Icons.notifications, color: visitorPrimary),
              ),
              title: Text(n.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(n.$2),
              trailing: Text(n.$3, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 24),
          _contactCard(Icons.location_on, 'Address',
              'SRIMCA Campus, Gujarat, India'),
          _contactCard(Icons.phone, 'Phone', '+91 98765 43210'),
          _contactCard(Icons.email, 'Email', 'info@srimca.edu.in'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Icon(Icons.chat),
              label: const Text('Chat with AI Assistant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: visitorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: visitorPrimary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
