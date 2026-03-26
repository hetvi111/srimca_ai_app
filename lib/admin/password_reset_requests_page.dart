import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'dart:convert';

class PasswordResetRequestsPage extends StatefulWidget {
  const PasswordResetRequestsPage({super.key});

  @override
  State<PasswordResetRequestsPage> createState() => _PasswordResetRequestsPageState();
}

class _PasswordResetRequestsPageState extends State<PasswordResetRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    final requests = await ApiService.getPasswordRequests();
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadRequests();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _resetPassword(String requestId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService.adminResetPassword(requestId);
    Navigator.pop(context); // Close loading

    if (result != null && result['message'] == 'Password reset successful') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Password reset: ${result['new_password']}')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      _loadRequests(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['error'] ?? 'Reset failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset Requests'),
        backgroundColor: const Color(0xFF1F4E8C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_open, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final status = request['status'] ?? 'pending';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status),
                            child: Text(
                              status[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(request['email'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${status.toUpperCase()}'),
                              Text('Requested: ${_formatDate(request['created_at'])}'),
                            ],
                          ),
                          trailing: status.toLowerCase() == 'pending'
                              ? ElevatedButton(
                                  onPressed: () => _resetPassword(request['_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[400],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reset PW'),
                                )
                              : const Icon(Icons.check_circle, color: Colors.green),
                          onTap: status.toLowerCase() == 'pending' ? () => _resetPassword(request['_id']) : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

