import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

class AdminEditUserPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> initialData;

  const AdminEditUserPage({
    super.key,
    required this.userId,
    this.initialData = const {},
  });

  @override
  State<AdminEditUserPage> createState() => _AdminEditUserPageState();
}

class _AdminEditUserPageState extends State<AdminEditUserPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  String _role = 'student';
  String _gender = 'male';
  bool _isActive = true;

  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _roles = ['student', 'faculty'];
  final List<String> _genders = ['male', 'female', 'other'];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    
    _applyUserToForm(widget.initialData);
    _fetchUser();
  }

  void _applyUserToForm(Map<String, dynamic> user) {
    _nameController.text = (user['name'] ?? '').toString();
    _emailController.text = (user['email'] ?? '').toString();

    // Phone is stored top-level as `mobile` in this project, but support profile.phone too.
    _phoneController.text = (user['mobile'] ??
            user['phone'] ??
            (user['profile']?['phone']))?.toString() ??
        '';

    final role = (user['role'] ?? 'student').toString().toLowerCase();
    _role = _roles.contains(role) ? role : 'student';

    _isActive = (user['is_active'] ?? user['is_active'] ?? user['isActive'] ?? true) == true;

    final gender = (user['gender'] ?? (user['profile']?['gender']) ?? 'male')
        .toString()
        .toLowerCase();
    _gender = _genders.contains(gender) ? gender : 'male';
  }

  Future<void> _fetchUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getAdminUserById(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _applyUserToForm(user);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUser() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    try {
      final result = await ApiService.adminUpdateUser(
        userId: widget.userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        role: _role,
        phone: _phoneController.text.trim(),
        gender: _gender,
        isActive: _isActive,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.pop(context, true); // Notify parent to refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Update failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        backgroundColor: const Color(0xFF1F4E8C),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveUser,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Email is required';
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _role = v ?? 'student'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: _genders
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.capitalize()),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v ?? 'male'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: const Text('User can login'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4E8C),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Update User", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// Extension for capitalize
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

