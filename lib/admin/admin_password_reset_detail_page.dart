import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// Admin sets new password for pending forgot-password request.
class AdminPasswordResetDetailPage extends StatefulWidget {
  const AdminPasswordResetDetailPage({super.key, required this.request});

  final Map<String, dynamic> request;

  @override
  State<AdminPasswordResetDetailPage> createState() => _AdminPasswordResetDetailPageState();
}

class _AdminPasswordResetDetailPageState extends State<AdminPasswordResetDetailPage> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _busy = false;
  String? _enrollmentOrEmail;

  String get _requestId => widget.request['_id']?.toString() ?? '';
  String get _email => widget.request['email']?.toString() ?? '';
  String get _role => (widget.request['user_role'] ?? '').toString().toLowerCase();
  String get _name => widget.request['user_name']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    if (_role == 'student') {
      _enrollmentOrEmail = widget.request['enrollment']?.toString();
    } else {
      _enrollmentOrEmail = _email;
    }
  }

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _performReset() async {
    debugPrint('Reset button pressed for $_email');
    if (_requestId.isEmpty) return;

    setState(() => _busy = true);
    try {
      if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
      if (_newPasswordCtrl.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
        return;
      }

      debugPrint('Calling API for $_requestId with new pw');
      final res = await ApiService.adminResetPassword(
        _requestId,
        newPassword: _newPasswordCtrl.text.trim(),
      );

      debugPrint('API response: $res');
      if (!mounted) return;

      if (res != null && res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully')),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['error']?.toString() ?? 'Reset failed')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.request['status'] ?? 'pending').toString().toLowerCase();
    final approved = status == 'approved';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request email: $_email', style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (_name.isNotEmpty) Text('Name: $_name'),
                    Text('Role: ${_role.isEmpty ? "—" : _role}'),
                    Text('Status: $status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (approved)
              const Text(
                'This request was already processed.',
                style: TextStyle(color: Colors.orange),
              )
            else ...[
              Text(
                'Account ID: ${_enrollmentOrEmail ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter new password twice:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  helperText: 'Minimum 6 characters',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_busy || approved || _newPasswordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) 
                    ? null 
                    : _performReset,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Set New Password'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

