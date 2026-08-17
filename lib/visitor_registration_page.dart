import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/visitor_auth_layout.dart';
import 'package:srimca_ai/visitor_theme.dart';

class VisitorRegistrationPage extends StatefulWidget {
  const VisitorRegistrationPage({super.key});

  @override
  State<VisitorRegistrationPage> createState() =>
      _VisitorRegistrationPageState();
}

class _VisitorRegistrationPageState extends State<VisitorRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facultyController = TextEditingController();
  String _selectedPurpose = 'Campus Visit';
  String _selectedDepartment = 'mca';
  String _visitorType = 'parent';
  bool _isLoading = false;

  final _departments = const {'bca': 'BCA', 'mca': 'MCA'};
  final _purposes = const [
    'Campus Visit',
    'admission',
    'meeting',
    'event',
    'placement',
    'other',
  ];
  final _visitorTypes = const [
    'parent',
    'student',
    'recruiter',
    'guest',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.registerVisitor(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        purpose: _selectedPurpose,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/visitor',
          arguments: {
            'userId': result['userId'],
            'token': result['token'],
            'userName': _nameController.text.trim(),
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisitorAuthLayout(
      title: 'Visitor Registration',
      subtitle:
          'Register your visit to SRIMCA and get access to AI assistance, digital pass, and more.',
      isLogin: false,
      onSwitchMode: () => Navigator.pushReplacementNamed(
        context,
        '/login',
        arguments: {'preselectRole': 'visitor'},
      ),
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth > 480;
                if (twoCol) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: _decoration('Full Name', icon: Icons.person),
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _decoration('Mobile Number', icon: Icons.phone),
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _decoration('Email Address', icon: Icons.email),
                              validator: (v) =>
                                  v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _visitorType,
                              decoration: _decoration('Visitor Type'),
                              items: _visitorTypes
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t[0].toUpperCase() + t.substring(1)),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _visitorType = v ?? _visitorType),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPurpose,
                              decoration: _decoration('Purpose of Visit'),
                              items: _purposes
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedPurpose = v ?? _selectedPurpose,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              decoration: _decoration('Department To Visit'),
                              items: _departments.entries
                                  .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedDepartment = v ?? _selectedDepartment,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _facultyController,
                        decoration: _decoration(
                          'Faculty To Meet (optional)',
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _decoration('Full Name', icon: Icons.person),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email Address', icon: Icons.email),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('Mobile Number', icon: Icons.phone),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPurpose,
                      decoration: _decoration('Purpose of Visit'),
                      items: _purposes
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedPurpose = v ?? _selectedPurpose),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: visitorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Register Visit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
