import 'package:flutter/material.dart';
import 'package:srimca_ai/visitor_theme.dart';

/// Split navy/white auth layout for visitor login & register (web design).
class VisitorAuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;
  final bool isLogin;
  final VoidCallback? onSwitchMode;

  const VisitorAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    this.isLogin = true,
    this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: isWide ? _buildWideLayout(context) : _buildNarrowLayout(context),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildLeftPanel()),
        Expanded(
          flex: 2,
          child: Container(
            color: visitorBg,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildFormCard(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 200, child: _buildLeftPanel(compact: true)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildFormCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel({bool compact = false}) {
    final features = isLogin
        ? [
            ('Track Your Visits', Icons.event_available),
            ('Get AI Assistance', Icons.smart_toy),
            ('Download Pass', Icons.qr_code),
            ('Stay Updated', Icons.notifications),
          ]
        : [
            ('AI Assistant Support', Icons.smart_toy),
            ('Quick Visit Approval', Icons.check_circle),
            ('Digital Visitor Pass', Icons.qr_code_2),
            ('Secure & Easy Process', Icons.security),
          ];

    return Container(
      color: visitorSidebar,
      padding: EdgeInsets.all(compact ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: visitorPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'SRIMCA AI ASSISTANT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 24 : 48),
          Text(
            isLogin ? 'Welcome Back!' : 'Welcome to SRIMCA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? 20 : 32),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(f.$2, color: visitorAccent, size: 22),
                  const SizedBox(width: 14),
                  Text(
                    f.$1,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          if (!compact) const Spacer(),
          if (!compact)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact: info@srimca.edu.in | +91 98765 43210',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: visitorNavy,
            ),
          ),
          const SizedBox(height: 24),
          form,
          if (onSwitchMode != null) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: onSwitchMode,
                child: Text(
                  isLogin
                      ? "Don't have an account? Register Here"
                      : 'Already have an account? Login Here',
                  style: const TextStyle(color: visitorPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
