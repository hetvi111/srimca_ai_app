import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/chat_screen.dart';

// Brand & Theme Colors
const Color vNavyDark = Color(0xFF001F3F);
const Color vNavyLight = Color(0xFF0B2545);
const Color vBlueAccent = Color(0xFF1E88E5);
const Color vSoftBg = Color(0xFFF8FAFC);
const Color vCardBg = Colors.white;
const Color vTextDark = Color(0xFF0F172A);
const Color vTextMuted = Color(0xFF64748B);

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
  List<dynamic> _notices = [];
  bool _loadingNotices = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName ?? 'Visitor';
    _token = widget.token;
    _loadVisitorData();
  }

  Future<void> _loadVisitorData() async {
    try {
      final user = await AuthService.getUser();
      if (user != null && user['name'] != null && user['name'].toString().isNotEmpty) {
        _displayName = user['name'].toString();
      }
      final notices = await ApiService.getNotices();
      if (mounted) {
        setState(() {
          _notices = notices;
          _loadingNotices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingNotices = false);
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await AuthService.clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vSoftBg,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(),
            _buildAIChatTab(),
            _buildNewsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: vBlueAccent,
          unselectedItemColor: vTextMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy_rounded),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper_rounded),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: HOME SCREEN LAYOUT
  // ==========================================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          _buildHeader(),
          const SizedBox(height: 18),

          // 2. Hero Section
          _buildHeroSection(),
          const SizedBox(height: 24),

          // 3. Quick Actions
          _buildSectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(),
          const SizedBox(height: 28),

          // 4. Featured Information Cards
          _buildSectionTitle('Featured Information'),
          const SizedBox(height: 12),
          _buildFeaturedCards(),
          const SizedBox(height: 28),

          // 5. AI Assistant Section (Ask SAI)
          _buildAskSAISection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 1. Header (SRIMCA Logo, Welcome Message, Search Icon, Profile/Guest Icon)
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            errorBuilder: (_, __, ___) => const Icon(Icons.school, color: vNavyDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $_displayName 👋',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: vTextDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'SRIMCA AI Campus Portal',
                style: TextStyle(
                  fontSize: 12,
                  color: vTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: vNavyDark),
          tooltip: 'Search SRIMCA Info',
          onPressed: _showSearchModal,
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 3),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: vBlueAccent.withValues(alpha: 0.15),
            child: Text(
              _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'V',
              style: const TextStyle(
                color: vBlueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Hero Section
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [vNavyDark, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: vNavyDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Campus AI Guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Welcome to SRIMCA\nAI Assistant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Shrimad Rajchandra Institute of Management & Computer Application, Uka Tarsadia University. Explore academics, admissions, and campus amenities.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text(
              'Ask AI',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vBlueAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Quick Actions Grid (Courses, Admissions, Fees, Faculty, Contact Us, Campus Location)
  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': 'Courses',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'onTap': () => _showInfoModal('Academic Courses', _coursesContent()),
      },
      {
        'title': 'Admissions',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
        'onTap': () => _showInfoModal('Admission Guidelines', _admissionsContent()),
      },
      {
        'title': 'Fees',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
        'onTap': () => _showInfoModal('Fee Structure & Scholarships', _feesContent()),
      },
      {
        'title': 'Faculty',
        'icon': Icons.badge_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'onTap': () => _showInfoModal('Faculty & Administration', _facultyContent()),
      },
      {
        'title': 'Contact Us',
        'icon': Icons.phone_in_talk_rounded,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
        'onTap': () => _showInfoModal('Contact & Inquiries', _contactContent()),
      },
      {
        'title': 'Location',
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF0891B2),
        'bg': const Color(0xFFECFEFF),
        'onTap': () => _showInfoModal('Campus Location & Transport', _locationContent()),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 6 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final a = actions[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: a['onTap'] as VoidCallback,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        color: a['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: vTextDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. Featured Information Cards
  Widget _buildFeaturedCards() {
    final cards = [
      {
        'title': 'About SRIMCA',
        'subtitle': 'College overview, Vision & Mission, AICTE approvals',
        'icon': Icons.account_balance_rounded,
        'badge': 'Overview',
        'color': const Color(0xFF2563EB),
        'onTap': () => _showInfoModal('About SRIMCA', _aboutSrimcaContent()),
      },
      {
        'title': 'Programs Offered',
        'subtitle': 'MCA (2-Yr), BCA (3-Yr), Integrated MCA (5-Yr), MBA',
        'icon': Icons.workspace_premium_rounded,
        'badge': 'Academics',
        'color': const Color(0xFF7C3AED),
        'onTap': () => _showInfoModal('Programs Offered', _coursesContent()),
      },
      {
        'title': 'Admission Information',
        'subtitle': 'Eligibility criteria, Required documents & ACPC process',
        'icon': Icons.checklist_rounded,
        'badge': 'Admissions',
        'color': const Color(0xFF059669),
        'onTap': () => _showInfoModal('Admission Information', _admissionsContent()),
      },
      {
        'title': 'Placement Highlights',
        'subtitle': 'Top recruiters (TCS, Infosys, Wipro), stats & training cell',
        'icon': Icons.trending_up_rounded,
        'badge': 'Careers',
        'color': const Color(0xFFD97706),
        'onTap': () => _showInfoModal('Placement Highlights', _placementsContent()),
      },
      {
        'title': 'Campus Facilities',
        'subtitle': '250+ PCs, 200 Mbps Wi-Fi, Library, AC Auditoriums & Hostels',
        'icon': Icons.apartment_rounded,
        'badge': 'Campus',
        'color': const Color(0xFF0891B2),
        'onTap': () => _showInfoModal('Campus Facilities', _facilitiesContent()),
      },
      {
        'title': 'Latest News & Events',
        'subtitle': 'Workshops, Seminars, TechFest, and Hackathons',
        'icon': Icons.event_available_rounded,
        'badge': 'Happenings',
        'color': const Color(0xFFE11D48),
        'onTap': () => setState(() => _selectedIndex = 2),
      },
    ];

    return Column(
      children: cards.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (c['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 24),
            ),
            title: Row(
              children: [
                Text(
                  c['title'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: vTextDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (c['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c['badge'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: c['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                c['subtitle'] as String,
                style: const TextStyle(fontSize: 12, color: vTextMuted),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: vTextMuted),
            onTap: c['onTap'] as VoidCallback,
          ),
        );
      }).toList(),
    );
  }

  // 5. AI Assistant Section ("Ask SAI" Card)
  Widget _buildAskSAISection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [const Color(0xFF0F172A), vNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: vBlueAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: vBlueAccent.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.cyanAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Ask SAI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'How can I help you today?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Instant answers for timetables, admissions, faculty contact, exams, and campus guidelines.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 1),
              icon: const Icon(Icons.forum_rounded, size: 18),
              label: const Text(
                'Start Chat',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: vBlueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: AI CHAT TAB
  // ==========================================
  Widget _buildAIChatTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: vNavyDark,
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              const Text(
                'SRIMCA AI Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                onPressed: () => _showInfoModal('About AI Assistant', _aiInfoContent()),
              ),
            ],
          ),
        ),
        Expanded(
          child: ChatScreen(
            token: _token,
            userId: widget.userId,
            embedded: true,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: NEWS & EVENTS TAB
  // ==========================================
  Widget _buildNewsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: vNavyDark,
          width: double.infinity,
          child: const Text(
            'Latest News & Campus Events',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _loadingNotices
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildEventHighlightCard(
                      'Epistemico & TechFest 2025',
                      'Annual National Technical Symposium featuring coding sprints, web design, and tech talks.',
                      'March 2025',
                      Icons.code_rounded,
                      Colors.indigo,
                    ),
                    _buildEventHighlightCard(
                      'MCA & BCA Admissions 2025-26 Open',
                      'Online application forms for MCA (ACPC) and BCA (UTU Portal) are now available.',
                      'Admissions Open',
                      Icons.school_rounded,
                      Colors.green,
                    ),
                    _buildEventHighlightCard(
                      'Industry Workshop on AI & Cloud',
                      'Hands-on workshop on Generative AI, Flutter, and Cloud Infrastructure by industry experts.',
                      'Upcoming',
                      Icons.psychology_rounded,
                      Colors.orange,
                    ),
                    if (_notices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Recent College Notices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: vTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._notices.map((n) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.campaign_rounded, color: vBlueAccent),
                              title: Text(
                                n['title']?.toString() ?? 'Notice',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                n['content']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEventHighlightCard(
    String title,
    String desc,
    String badge,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: vTextDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: vTextMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: PROFILE TAB
  // ==========================================
  Widget _buildProfileTab() {
    final isGuest = widget.userId == 'guest' || _displayName == 'Visitor' || _displayName == 'Guest Visitor';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: vNavyDark,
                  child: Text(
                    _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'V',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: vTextDark,
                  ),
                ),
                Text(
                  isGuest ? 'Guest Visitor Session' : 'Registered Campus Visitor',
                  style: const TextStyle(
                    fontSize: 13,
                    color: vTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Gate QR Pass Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.qr_code_rounded, color: vNavyDark),
                    SizedBox(width: 8),
                    Text(
                      'Campus Gate Entry QR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: vNavyDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Image.asset(
                    'assets/images/visitor_qr.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.qr_code_2_rounded,
                      size: 80,
                      color: vNavyDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Show this QR at campus security for seamless verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: vTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Actions
          _buildProfileTile(Icons.info_outline_rounded, 'About SRIMCA', () => _showInfoModal('About SRIMCA', _aboutSrimcaContent())),
          _buildProfileTile(Icons.headset_mic_rounded, 'Help & Support', () => _showInfoModal('Helpdesk Support', _contactContent())),
          _buildProfileTile(Icons.logout_rounded, isGuest ? 'Login as Registered User' : 'Logout', _logout, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : vNavyDark),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : vTextDark,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: vTextMuted),
        onTap: onTap,
      ),
    );
  }

  // ==========================================
  // HELPER MODALS & CONTENT BUILDERS
  // ==========================================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: vNavyDark,
        letterSpacing: -0.2,
      ),
    );
  }

  void _showInfoModal(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: vNavyDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchModal() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search SRIMCA courses, fees, admissions...',
                    prefixIcon: const Icon(Icons.search_rounded, color: vBlueAccent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: vBlueAccent),
                      onPressed: () {
                        final q = searchCtrl.text.trim();
                        if (q.isNotEmpty) {
                          Navigator.pop(ctx);
                          setState(() => _selectedIndex = 1);
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('MCA Fees'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showInfoModal('Fee Structure', _feesContent());
                      },
                    ),
                    ActionChip(
                      label: const Text('BCA Admission'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showInfoModal('Admission Information', _admissionsContent());
                      },
                    ),
                    ActionChip(
                      label: const Text('Campus Address'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showInfoModal('Campus Location', _locationContent());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Content Widgets for Dialogs ---
  Widget _aboutSrimcaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Shrimad Rajchandra Institute of Management and Computer Application (SRIMCA)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: vNavyDark),
        ),
        SizedBox(height: 8),
        Text(
          'Established in 2002 (MCA) and 2004 (MBA), SRIMCA is a premier constituent institute of Uka Tarsadia University (UTU). All programs are recognized by AICTE, New Delhi, and Government of Gujarat.',
          style: TextStyle(fontSize: 13, height: 1.4, color: vTextMuted),
        ),
        SizedBox(height: 16),
        Text('🌟 Vision', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 4),
        Text(
          'To become a globally recognized premier educational institute for academic excellence, innovation, and character building.',
          style: TextStyle(fontSize: 13, height: 1.4, color: vTextMuted),
        ),
        SizedBox(height: 12),
        Text('🎯 Mission', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 4),
        Text(
          'To remain on the cutting edge of education, research, industry partnerships, and social commitment.',
          style: TextStyle(fontSize: 13, height: 1.4, color: vTextMuted),
        ),
      ],
    );
  }

  Widget _coursesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('1. Master of Computer Applications (MCA)', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        Text('• Duration: 2 Years (4 Semesters)\n• Eligibility: Passed BCA/B.Sc/B.Com/BA with Mathematics with min 50%.\n• Admission: Through ACPC Gujarat & Management Quota.\n', style: TextStyle(fontSize: 13, color: vTextMuted)),
        Text('2. Bachelor of Computer Applications (BCA)', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        Text('• Duration: 3 Years (6 Semesters)\n• Eligibility: Passed 12th standard (HSC) in Science or Commerce.\n• Admission: Direct admission through UTU Admission Portal.\n', style: TextStyle(fontSize: 13, color: vTextMuted)),
        Text('3. Integrated MCA (5-Year)', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        Text('• Direct 5-year post-12th program leading to Master degree.\n', style: TextStyle(fontSize: 13, color: vTextMuted)),
        Text('4. Master of Business Administration (MBA)', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        Text('• Specializations in Marketing, Finance, HR, and International Business.', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _admissionsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('📋 Admission Process Steps:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 6),
        Text('1. Register online on UTU Admission Portal or ACPC portal for MCA.\n2. Submit 10th, 12th, and Graduation marksheets.\n3. Participate in seat allotment or campus counselling.\n4. Confirm admission by submitting tuition fee token.', style: TextStyle(fontSize: 13, color: vTextMuted)),
        SizedBox(height: 14),
        Text('📄 Required Documents Checklist:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 6),
        Text('• 10th & 12th Marksheets\n• Degree Marksheets (for MCA/MBA)\n• School/College Leaving Certificate (LC)\n• Caste/Income Certificate (if applicable)\n• Passport size photographs & Aadhar Card', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _feesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('💰 Tuition & Academic Fees (Per Year):', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('• MCA: Approx. ₹65,000 - ₹75,000 / year\n• BCA: Approx. ₹45,000 - ₹55,000 / year\n• MBA: Approx. ₹68,000 - ₹78,000 / year\n', style: TextStyle(fontSize: 13, color: vTextMuted)),
        Text('🎓 Scholarships Available:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 6),
        Text('• Digital Gujarat Government Scholarships (SC/ST/SEBC/EWS)\n• MYSY (Mukhyamantri Yuva Swavalamban Yojana)\n• University Merit Scholarships for top rankers', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _facultyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('👨‍🏫 Esteemed Faculty & Mentors:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('SRIMCA boasts highly qualified professors with Ph.D. and M.Tech degrees, having extensive research publications and industry experience in AI, Cloud, Cybersecurity, and Software Engineering.', style: TextStyle(fontSize: 13, color: vTextMuted)),
        SizedBox(height: 12),
        Text('• Mentorship Program: Each student is assigned a dedicated faculty counselor.\n• Project Guidance: Hands-on industry project mentors for final-year dissertations.', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _contactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('📞 Get in Touch with SRIMCA:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('• Phone: +91 2625 290074 / 290075\n• Email: director.srimca@utu.ac.in\n• Admissions Helpline: +91 99099 12345\n• Official Website: www.utu.ac.in / srimca.utu.ac.in', style: TextStyle(fontSize: 13, color: vTextMuted)),
        SizedBox(height: 12),
        Text('🕒 Campus Office Hours: Monday - Saturday (8:30 AM - 4:30 PM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: vNavyDark)),
      ],
    );
  }

  Widget _locationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('📍 Campus Location & Address:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('Maliba Campus, Gopal Vidyanagar, Bardoli-Mahuva Road, Tarsadi, Surat, Gujarat - 394350.\n', style: TextStyle(fontSize: 13, color: vTextMuted)),
        Text('🚌 Transportation & Commute:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 6),
        Text('• University buses ply from Surat, Navsari, Bardoli, Vyara, Kadod, and Valod.\n• 15 mins drive from Bardoli Railway Station.\n• 45 mins from Surat Railway Station.', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _placementsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('💼 Campus Placement Highlights:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('• Highest Package: ₹8.5 LPA\n• Average Package: ₹3.8 - ₹4.5 LPA\n• Over 85% placement record for eligible students.\n', style: TextStyle(fontSize: 13, color: vTextMuted)),
        Text('🏢 Top Hiring Partners:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 6),
        Text('TCS, Infosys, Wipro, L&T Infotech, Capgemini, TatvaSoft, Bacancy, WebOccult, Dhyey Consulting, and 50+ IT recruiters.', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _facilitiesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('🏛️ World-Class Campus Amenities:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('• 250+ High-Performance Computer Labs with Gigabit LAN\n• 200 Mbps Dedicated Internet Leased Line & Wi-Fi\n• Central Digital Library with IEEE/ACM Journals\n• Air-conditioned 500-seat Auditorium & Seminar Halls\n• Sports ground, Gym, Canteen, and on-campus Hostels', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }

  Widget _aiInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('🤖 About SRIMCA AI Assistant:', style: TextStyle(fontWeight: FontWeight.bold, color: vNavyDark)),
        SizedBox(height: 8),
        Text('Powered by state-of-the-art AI and SRIMCA academic database, providing instant 24/7 answers regarding syllabus, exam timetables, notices, admissions, and campus amenities.', style: TextStyle(fontSize: 13, color: vTextMuted)),
      ],
    );
  }
}
