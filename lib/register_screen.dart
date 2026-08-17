import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/push_notification_service.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Student specific controllers
  final _enrollmentController = TextEditingController();
  final _dobController = TextEditingController();

  // Faculty specific controllers
  final _designationController = TextEditingController();

  // Visitor specific controllers
  final _addressController = TextEditingController();

  // State selections
  String _selectedRole = 'student'; // 'student', 'faculty', 'visitor'
  String _selectedSemester = '1';
  String _selectedDepartment = 'mca';
  String _selectedPurpose = 'Campus Visit';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Theme Colors
  static const Color navyDark = Color(0xFF001F3F);
  static const Color navyMedium = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color lightIndigo = Color(0xFF3949AB);

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6'];
  final Map<String, String> _departments = {
    'mca': 'Master of Computer Applications (MCA)',
    'bca': 'Bachelor of Computer Applications (BCA)',
    'int_mca': 'Integrated MCA (5 Years)',
    'imba': 'Integrated MBA',
  };

  final Map<String, String> _purposes = {
    'Campus Visit': 'General Campus Visit',
    'admission': 'Admission Inquiry',
    'meeting': 'Meeting with Faculty / Staff',
    'event': 'Campus Event / Workshop',
    'placement': 'Placement / Recruitment Drive',
    'other': 'Other Official Purpose',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null && widget.initialRole!.isNotEmpty) {
      final role = widget.initialRole!.toLowerCase();
      if (['student', 'faculty', 'visitor'].contains(role)) {
        _selectedRole = role;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _enrollmentController.dispose();
    _dobController.dispose();
    _designationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 20, 1, 1);
    final DateTime firstDate = DateTime(now.year - 60);
    final DateTime lastDate = DateTime(now.year - 15);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accentBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF1A237E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> requestBody = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'password': password,
        'role': _selectedRole.toLowerCase(),
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (_selectedRole == 'student') {
        requestBody['enrollment'] = _enrollmentController.text.trim();
        requestBody['dob'] = _dobController.text.trim();
        requestBody['semester'] = _selectedSemester;
        requestBody['department'] = _selectedDepartment;
      } else if (_selectedRole == 'faculty') {
        requestBody['department'] = _selectedDepartment;
        requestBody['designation'] = _designationController.text.trim();
      } else if (_selectedRole == 'visitor') {
        requestBody['purpose'] = _selectedPurpose;
      }

      final result = await ApiService.registerUser(body: requestBody);

      if (!mounted) return;

      if (result['success'] == true) {
        final responseData = result['data'] as Map<String, dynamic>?;
        final token = responseData?['token'] as String?;
        final user = responseData?['user'] as Map<String, dynamic>?;

        if (token != null && token.isNotEmpty) {
          await AuthService.saveToken(token);
        }
        if (user != null) {
          await AuthService.saveUser(user);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (user != null) {
          final String role = (user['role'] as String? ?? _selectedRole).toLowerCase();

          try {
            if (role.isNotEmpty && !kIsWeb) {
              await PushNotificationService.subscribeToRoleTopics(role);
            }
          } catch (e) {
            debugPrint('FCM topic subscription failed: $e');
          }

          if (!mounted) return;

          switch (role) {
            case 'admin':
              Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
              break;
            case 'faculty':
              Navigator.pushNamedAndRemoveUntil(context, '/faculty', (route) => false);
              break;
            case 'student':
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/student',
                (route) => false,
                arguments: {
                  'studentName': user['name'] ?? 'Student',
                  'semester': user['semester'] ?? _selectedSemester,
                  'userId': user['_id'] ?? '',
                  'email': user['email'] ?? '',
                  'enrollmentNumber': user['enrollment'] ?? _enrollmentController.text.trim(),
                  'course': user['department'] ?? _selectedDepartment,
                },
              );
              break;
            case 'visitor':
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/visitor',
                (route) => false,
                arguments: {
                  'userId': user['_id'] ?? '',
                  'token': token ?? '',
                  'userName': user['name'] ?? 'Visitor',
                },
              );
              break;
            default:
              Navigator.pushNamedAndRemoveUntil(context, '/first', (route) => false);
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Registration failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              navyDark,
              navyMedium,
              lightIndigo,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button & Title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                          tooltip: 'Back',
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(context, '/first');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Padding(
                      padding: EdgeInsets.only(left: 48.0),
                      child: Text(
                        'Select your role and complete your registration',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Role Selection Pills
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          _buildRoleButton('student', 'Student', Icons.school_outlined),
                          _buildRoleButton('faculty', 'Faculty', Icons.person_outline_rounded),
                          _buildRoleButton('visitor', 'Visitor', Icons.badge_outlined),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Registration Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Full Name
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                            ),

                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Email Address',
                                hint: 'example@srimca.edu',
                                icon: Icons.email_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter email';
                                if (!v.contains('@')) return 'Enter a valid email address';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Mobile Number
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Mobile Number',
                                hint: '10-digit phone number',
                                icon: Icons.phone_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                                if (v.trim().length < 8) return 'Enter a valid phone number';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // ================= Student Specific Fields =================
                            if (_selectedRole == 'student') ...[
                              // Enrollment
                              TextFormField(
                                controller: _enrollmentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Enrollment Number',
                                  hint: 'e.g. 20240101...',
                                  icon: Icons.confirmation_number_outlined,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Enter enrollment number' : null,
                              ),

                              const SizedBox(height: 16),

                              // Date of Birth
                              TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                onTap: _selectDateOfBirth,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Date of Birth',
                                  hint: 'YYYY-MM-DD',
                                  icon: Icons.calendar_today_outlined,
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.date_range_rounded, color: Colors.white70),
                                    onPressed: _selectDateOfBirth,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Select date of birth' : null,
                              ),

                              const SizedBox(height: 16),

                              // Department / Course Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedDepartment,
                                dropdownColor: const Color(0xFF1A237E),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Course / Department',
                                  hint: 'Select your course',
                                  icon: Icons.domain_outlined,
                                ),
                                items: _departments.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(
                                            e.value,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedDepartment = v ?? 'mca'),
                              ),

                              const SizedBox(height: 16),

                              // Semester Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSemester,
                                dropdownColor: const Color(0xFF1A237E),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Semester',
                                  hint: 'Select current semester',
                                  icon: Icons.layers_outlined,
                                ),
                                items: _semesters
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text("Semester $s", style: const TextStyle(color: Colors.white)),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedSemester = v ?? '1'),
                              ),

                              const SizedBox(height: 16),
                            ],

                            // ================= Faculty Specific Fields =================
                            if (_selectedRole == 'faculty') ...[
                              // Department Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedDepartment,
                                dropdownColor: const Color(0xFF1A237E),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Department',
                                  hint: 'Select department',
                                  icon: Icons.domain_outlined,
                                ),
                                items: _departments.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(
                                            e.value,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedDepartment = v ?? 'mca'),
                              ),

                              const SizedBox(height: 16),

                              // Designation
                              TextFormField(
                                controller: _designationController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Designation',
                                  hint: 'e.g. Professor, Associate Professor, HOD',
                                  icon: Icons.badge_outlined,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Enter designation' : null,
                              ),

                              const SizedBox(height: 16),
                            ],

                            // ================= Visitor Specific Fields =================
                            if (_selectedRole == 'visitor') ...[
                              // Purpose of Visit Dropdown
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPurpose,
                                dropdownColor: const Color(0xFF1A237E),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'Purpose of Visit',
                                  hint: 'Select purpose',
                                  icon: Icons.assignment_turned_in_outlined,
                                ),
                                items: _purposes.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value, style: const TextStyle(color: Colors.white)),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedPurpose = v ?? 'Campus Visit'),
                              ),

                              const SizedBox(height: 16),

                              // Address / City
                              TextFormField(
                                controller: _addressController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  label: 'City / Address',
                                  hint: 'e.g. Bardoli, Surat',
                                  icon: Icons.location_on_outlined,
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Password',
                                hint: 'At least 6 characters',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.white60,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter password';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                icon: Icons.lock_reset_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white60,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please confirm password';
                                return null;
                              },
                            ),

                            const SizedBox(height: 28),

                            // Submit Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer -> Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF64B5F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentBlue.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }
}
