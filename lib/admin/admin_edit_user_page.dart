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

  final List<String> _roles = ['student', 'faculty', 'visitor'];
  final List<String> _genders = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Prefill data
    _nameController.text = widget.initialData['name'] ?? '';
    _emailController.text = widget.initialData['email'] ?? '';
    _phoneController.text = widget.initialData['profile']?['phone'] ?? '';
    _role = widget.initialData['role'] ?? 'student';
    _isActive = widget.initialData['is_active'] ?? true;
    // Gender from profile
    _gender = widget.initialData['profile']?['gender'] ?? 'male';
  }

  Future<void> _saveUser() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ApiService.updateUser(
        userId: widget.userId,
        name: _nameController.text,
        email: _emailController.text,
        role: _role,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.pop(context, true); // Notify parent to refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Role
            ListTile(
              title: const Text('Role'),
              trailing: DropdownButton<String>(
                value: _role,
                items: _roles.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                )).toList(),
                onChanged: (value) => setState(() => _role = value!),
              ),
            ),
            const SizedBox(height: 16),
            // Gender
            ListTile(
              title: const Text('Gender'),
              trailing: DropdownButton<String>(
                value: _gender,
                items: _genders.map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender.capitalize()),
                )).toList(),
                onChanged: (value) => setState(() => _gender = value!),
              ),
            ),
            // Status
            SwitchListTile(
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

