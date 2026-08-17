import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/visitor_qr_page.dart';
import 'package:srimca_ai/visitor_theme.dart';

class VisitorProfilePage extends StatefulWidget {
  final String userId;
  final String token;

  /// When true, renders content only (no Scaffold/AppBar) for portal embedding.
  final bool embedded;

  const VisitorProfilePage({
    super.key,
    required this.userId,
    required this.token,
    this.embedded = false,
  });

  @override
  State<VisitorProfilePage> createState() => _VisitorProfilePageState();
}

class _VisitorProfilePageState extends State<VisitorProfilePage> {
  Map<String, dynamic> profileData = {};
  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (widget.userId == 'guest' || widget.userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final profile = await ApiService.getProfile(widget.token, widget.userId);
      final logs = await ApiService.getHistory(widget.token, widget.userId);
      setState(() {
        profileData = profile ?? {};
        history = logs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    await AuthService.clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildPersonalInfoCard(),
                const SizedBox(height: 20),
                _buildQuickActionsCard(),
                const SizedBox(height: 20),
                _buildVisitHistoryTable(),
                if (!widget.embedded) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ],
            ),
          );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Profile'),
        backgroundColor: visitorNavy,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _buildHeaderCard() {
    final name = profileData['name']?.toString() ?? 'Visitor';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: visitorPrimary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'V',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: visitorPrimary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: visitorNavy,
                  ),
                ),
                Text(
                  'Visitor ID: ${widget.userId.length > 8 ? widget.userId.substring(0, 8) : widget.userId}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profileData['status']?.toString() ?? 'Approved Visitor',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _sectionCard(
      'Personal Information',
      [
        _infoRow('Full Name', profileData['name'] ?? 'N/A'),
        _infoRow('Mobile Number', profileData['phone'] ?? 'N/A'),
        _infoRow('Email', profileData['email'] ?? 'N/A'),
        _infoRow('Visitor Type', profileData['visitor_type'] ?? 'General'),
        _infoRow('Purpose', profileData['purpose'] ?? 'N/A'),
        _infoRow('Registration Date',
            profileData['created_at']?.toString().split('T').first ?? 'N/A'),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return _sectionCard(
      'Quick Actions',
      [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisitorQRPage(
                      token: widget.token,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: visitorPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.qr_code),
              label: const Text('Download Pass'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/forgot-password'),
              icon: const Icon(Icons.lock),
              label: const Text('Change Password'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitHistoryTable() {
    return _sectionCard(
      'Visit History',
      [
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No visits yet'),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(visitorBg),
              columns: const [
                DataColumn(label: Text('Department')),
                DataColumn(label: Text('Visit Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: history.map<DataRow>((item) {
                return DataRow(cells: [
                  DataCell(Text(
                    profileData['department']?.toString() ?? 'MCA',
                  )),
                  DataCell(Text(item['check_in']?.toString() ?? 'N/A')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['status']?.toString() ?? 'Approved',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisitorQRPage(
                              token: widget.token,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Pass'),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: visitorNavy,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
