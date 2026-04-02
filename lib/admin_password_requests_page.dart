import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/admin_password_reset_detail_page.dart';

class AdminPasswordRequestsPage extends StatefulWidget {
  const AdminPasswordRequestsPage({super.key});

  @override
  State<AdminPasswordRequestsPage> createState() => _AdminPasswordRequestsPageState();
}

class _AdminPasswordRequestsPageState extends State<AdminPasswordRequestsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final reqs = await ApiService.getPasswordRequests(limit: 200);
      if (!mounted) return;
      setState(() {
        _requests = reqs;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> r) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPasswordResetDetailPage(request: r),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset Requests'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final r = _requests[index];
                    final email = r['email']?.toString() ?? '';
                    final status = (r['status'] ?? 'pending').toString();
                    final role = r['user_role']?.toString() ?? '';
                    final name = r['user_name']?.toString() ?? '';

                    return Card(
                      child: ListTile(
                        title: Text(email),
                        subtitle: Text(
                          [
                            if (name.isNotEmpty) name,
                            if (role.isNotEmpty) 'Role: $role',
                            if (role.toLowerCase() == 'student' && r['enrollment'] != null && r['enrollment'].toString().isNotEmpty) 'Enrollment: ${r['enrollment']}',
                            if (role.toLowerCase() != 'student') 'Email: $email',
                            'Status: $status',
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetail(r),
                      ),
                    );
                  },
                ),
    );
  }
}

