import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

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

  Future<void> _resetPassword(String requestId) async {
    final res = await ApiService.adminResetPassword(requestId);
    if (!mounted) return;

    if (res != null && res['success'] == true) {
      final newPassword = res['new_password']?.toString() ?? '';
      await _load();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('New Password'),
          content: SelectableText(newPassword.isEmpty ? 'Generated' : newPassword),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res?['error']?.toString() ?? 'Reset failed')),
    );
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
                    final id = r['_id']?.toString() ?? '';
                    final email = r['email']?.toString() ?? '';
                    final status = (r['status'] ?? 'pending').toString();
                    final approved = status.toLowerCase() == 'approved';

                    return Card(
                      child: ListTile(
                        title: Text(email),
                        subtitle: Text('Status: $status'),
                        trailing: ElevatedButton(
                          onPressed: approved || id.isEmpty ? null : () => _resetPassword(id),
                          child: const Text('Reset Password'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

