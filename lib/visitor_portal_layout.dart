import 'package:flutter/material.dart';
import 'package:srimca_ai/visitor_theme.dart';

class VisitorPortalLayout extends StatefulWidget {
  final String userName;
  final int selectedIndex;
  final ValueChanged<int> onNavTap;
  final Widget child;
  final int notificationCount;

  const VisitorPortalLayout({
    super.key,
    required this.userName,
    required this.selectedIndex,
    required this.onNavTap,
    required this.child,
    this.notificationCount = 0,
  });

  @override
  State<VisitorPortalLayout> createState() => _VisitorPortalLayoutState();
}

class _VisitorPortalLayoutState extends State<VisitorPortalLayout> {
  bool _sidebarExpanded = true;

  static const _navItems = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.event_note_outlined, Icons.event_note, 'My Visits'),
    (Icons.smart_toy_outlined, Icons.smart_toy, 'AI Assistant'),
    (Icons.notifications_outlined, Icons.notifications, 'Notifications'),
    (Icons.person_outline, Icons.person, 'Profile'),
    (Icons.contact_support_outlined, Icons.contact_support, 'Contact Us'),
    (Icons.logout, Icons.logout, 'Logout'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: visitorBg,
      body: Row(
        children: [
          if (isWide) _buildSidebar(isWide),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: visitorSidebar,
              child: _buildSidebar(false),
            ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          if (isWide)
            IconButton(
              icon: Icon(
                _sidebarExpanded ? Icons.menu_open : Icons.menu,
                color: visitorNavy,
              ),
              onPressed: () =>
                  setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: visitorNavy,
                onPressed: () => widget.onNavTap(3),
              ),
              if (widget.notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: visitorPrimary.withValues(alpha: 0.15),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'V',
                  style: const TextStyle(
                    color: visitorPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: visitorNavy,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: visitorNavy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isWide) {
    final width = isWide && _sidebarExpanded ? 260.0 : (isWide ? 72.0 : 280.0);
    final showLabels = !isWide || _sidebarExpanded;

    return Container(
      width: width,
      color: visitorSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: visitorPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SRIMCA\nVisitor Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = widget.selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: selected
                        ? visitorPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (!isWide) Navigator.pop(context);
                        widget.onNavTap(index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? item.$2 : item.$1,
                              color: Colors.white,
                              size: 22,
                            ),
                            if (showLabels) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.$3,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (index == 3 && widget.notificationCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${widget.notificationCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (showLabels)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.headset_mic, color: Colors.white70),
                    const SizedBox(height: 8),
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Our support team is here to assist you.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => widget.onNavTap(5),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
