import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:srimca_ai/api_service.dart';

const Color kAdminPrimary = Color(0xFF001F3F); // Navy Blue
const Color kAdminAccent = Color(0xFF1E88E5); // Vibrant Blue
const Color kAdminCardBg = Colors.white;
const Color kAdminTextDark = Color(0xFF0F172A);
const Color kAdminTextMuted = Color(0xFF64748B);

class AdminUserManagementView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AdminUserManagementView({super.key, this.onBackToDashboard});

  @override
  State<AdminUserManagementView> createState() => _AdminUserManagementViewState();
}

typedef UserManagementView = AdminUserManagementView;

class _AdminUserManagementViewState extends State<AdminUserManagementView> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getAdminUsersList(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole,
        status: _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),

          // Filters & Search Bar
          _buildFilterBar(),
          const SizedBox(height: 16),

          // Users Table / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
                : _users.isEmpty
                    ? _buildEmptyState()
                    : _buildUsersTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management & Role Permissions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAdminTextDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage registered accounts, role privileges (Admin, Student, Faculty, Visitor), and security status.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openAddEditUserDialog(),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Create User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kAdminAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, email, phone, enrollment number...',
                prefixIcon: Icon(Icons.search, size: 20, color: kAdminTextMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _fetchUsers();
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedRole,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Roles', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'student', child: Text('Students', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'faculty', child: Text('Faculty', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'visitor', child: Text('Visitors', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'admin', child: Text('Administrators', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedRole = val);
                _fetchUsers();
              }
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedStatus,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'active', child: Text('Active Only', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive Only', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
                _fetchUsers();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No users found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAdminTextDark)),
          const SizedBox(height: 6),
          const Text('Try adjusting your search query or role filter.', style: TextStyle(color: kAdminTextMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final user = _users[i];
          final id = user['_id']?.toString() ?? '';
          final name = user['name']?.toString() ?? 'User';
          final email = user['email']?.toString() ?? '';
          final role = (user['role'] ?? 'student').toString().toLowerCase();
          final mobile = user['mobile']?.toString() ?? '';
          final isActive = user['is_active'] == true;
          final created = user['created_at']?.toString() ?? '';

          Color roleColor = const Color(0xFF1E88E5);
          if (role == 'faculty') {
            roleColor = const Color(0xFF00897B);
          } else if (role == 'visitor') {
            roleColor = const Color(0xFFFB8C00);
          } else if (role == 'admin') {
            roleColor = const Color(0xFF8E24AA);
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAdminTextDark),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isActive ? Colors.green.shade300 : Colors.red.shade300),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '$email ${mobile.isNotEmpty ? "• $mobile" : ""}',
                  style: const TextStyle(fontSize: 12, color: kAdminTextDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registered: ${_formatDate(created)}',
                  style: const TextStyle(fontSize: 11, color: kAdminTextMuted),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'View Profile Details',
                  icon: const Icon(Icons.info_outline_rounded, color: kAdminAccent),
                  onPressed: () => _showUserDetailsDialog(user),
                ),
                IconButton(
                  tooltip: isActive ? 'Deactivate Account' : 'Activate Account',
                  icon: Icon(
                    isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    size: 32,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  onPressed: () async {
                    final success = await ApiService.toggleAdminUserStatus(id);
                    if (success) {
                      _fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account status updated for $email')),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Edit Account',
                  icon: const Icon(Icons.edit_rounded, color: Colors.blueGrey),
                  onPressed: () => _openAddEditUserDialog(user: user),
                ),
                IconButton(
                  tooltip: 'Delete User',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteUser(id, name, email),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> u) {
    final profile = u['profile'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: kAdminAccent),
            const SizedBox(width: 8),
            Text(u['name']?.toString() ?? 'User Profile'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('User ID', u['_id']?.toString() ?? ''),
              _buildDetailRow('Email', u['email']?.toString() ?? ''),
              _buildDetailRow('Role', (u['role'] ?? '').toString().toUpperCase()),
              _buildDetailRow('Mobile', u['mobile']?.toString() ?? 'N/A'),
              _buildDetailRow('Account Status', u['is_active'] == true ? 'Active' : 'Inactive'),
              if (u['department'] != null && u['department'].toString().isNotEmpty)
                _buildDetailRow('Department', u['department'].toString()),
              if (u['semester'] != null && u['semester'].toString().isNotEmpty)
                _buildDetailRow('Semester', u['semester'].toString()),
              if (u['enrollment'] != null && u['enrollment'].toString().isNotEmpty)
                _buildDetailRow('Enrollment No.', u['enrollment'].toString()),
              if (profile['address'] != null && profile['address'].toString().isNotEmpty)
                _buildDetailRow('Address', profile['address'].toString()),
              _buildDetailRow('Created At', _formatDate(u['created_at']?.toString() ?? '')),
              _buildDetailRow('Last Login', _formatDate(u['last_login']?.toString() ?? 'Never')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kAdminTextMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 13, color: kAdminTextDark),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddEditUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: user?['email']?.toString() ?? '');
    final mobileCtrl = TextEditingController(text: user?['mobile']?.toString() ?? '');
    final passwordCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: user?['department']?.toString() ?? '');
    final semCtrl = TextEditingController(text: user?['semester']?.toString() ?? '');
    final enrollCtrl = TextEditingController(text: user?['enrollment']?.toString() ?? '');

    String role = user?['role']?.toString().toLowerCase() ?? 'student';
    bool isActive = user?['is_active'] ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Account Permissions' : 'Create User Account'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        enabled: !isEdit, // Email is immutable identity in edit
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'user@student.srimca.edu',
                          border: const OutlineInputBorder(),
                          filled: isEdit,
                          fillColor: isEdit ? Colors.grey.shade100 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: role,
                              decoration: const InputDecoration(labelText: 'Assigned Role', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'student', child: Text('Student')),
                                DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                                DropdownMenuItem(value: 'visitor', child: Text('Visitor')),
                                DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => role = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: mobileCtrl,
                              decoration: const InputDecoration(labelText: 'Mobile Phone', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit ? 'Reset Password (optional)' : 'Password *',
                          hintText: isEdit ? 'Leave blank to keep unchanged' : 'Min 6 characters',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (role == 'student') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: deptCtrl,
                                decoration: const InputDecoration(labelText: 'Department / Course (e.g. MCA)', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: semCtrl,
                                decoration: const InputDecoration(labelText: 'Semester (e.g. 4th)', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: enrollCtrl,
                          decoration: const InputDecoration(labelText: 'Enrollment Number', border: OutlineInputBorder()),
                        ),
                      ],
                      if (role == 'faculty') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: deptCtrl,
                          decoration: const InputDecoration(labelText: 'Department (e.g. Computer Science)', border: OutlineInputBorder()),
                        ),
                      ],
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Account Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          value: isActive,
                          activeColor: Colors.green,
                          onChanged: (val) => setDialogState(() => isActive = val),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final password = passwordCtrl.text.trim();

                    if (name.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name and Email are required')),
                      );
                      return;
                    }

                    if (!isEdit && password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password must be at least 6 characters')),
                      );
                      return;
                    }

                    final payload = {
                      'name': name,
                      'email': email,
                      'role': role,
                      'mobile': mobileCtrl.text.trim(),
                      'department': deptCtrl.text.trim(),
                      'semester': semCtrl.text.trim(),
                      'enrollment': enrollCtrl.text.trim(),
                      if (password.isNotEmpty) 'password': password,
                      if (isEdit) 'is_active': isActive,
                    };

                    Navigator.pop(ctx);
                    if (isEdit) {
                      final id = user['_id']?.toString() ?? '';
                      final res = await ApiService.updateAdminUserAccount(id, payload);
                      if (res['success'] == true) {
                        _fetchUsers();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account updated')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to update account')),
                        );
                      }
                    } else {
                      final res = await ApiService.createAdminUserAccount(payload);
                      if (res['success'] == true) {
                        _fetchUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User account created successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to create user account')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kAdminAccent, foregroundColor: Colors.white),
                  child: Text(isEdit ? 'Save Changes' : 'Create Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(String id, String name, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account'),
        content: Text('Are you sure you want to delete user "$name" ($email)? This will permanently remove access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteAdminUserAccount(id);
              if (success) {
                _fetchUsers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete user account')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
