import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:srimca_ai/static_data.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/firebase_service.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _dobController = TextEditingController();

  String _selectedSemester = '';
  String _selectedDepartment = '';
  String _selectedPurpose = '';

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6'];
  final List<String> _departments = [
  'bca',
  'mca',
];
  final List<String> _purposes = [
    'admission',
    'placement',
    'meeting',
    'event',
    'tour',
    'other',
  ];

  final Map<String, String> _departmentLabels = {
  'bca': 'Bachelor of Computer Applications (BCA)',
  'mca': 'Master of Computer Applications (MCA)',
};
  final Map<String, String> _purposeLabels = {
    'admission': 'Admission Inquiry',
    'placement': 'Placement/Recruitment',
    'meeting': 'Meeting with Faculty',
    'event': 'College Event',
    'tour': 'Campus Tour',
    'other': 'Other',
  };

  bool get _isStudent => _selectedRole.toLowerCase() == 'student';
  bool get _isVisitor => _selectedRole.toLowerCase() == 'visitor';

  bool _obscurePassword = true;
  String _selectedRole = 'student';
  final List<String> _roles = ['student', 'faculty', 'admin', 'visitor'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _enrollmentController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D2A47), Color(0xFF4A3F6F), Color(0xFF6B5B95)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Image.asset(
                    'assets/images/logo.png', // replace with your logo
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SRIMCA AI Assistant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF9D7FD8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab, // ⭐ VERY IMPORTANT
                      indicatorPadding: EdgeInsets.zero,      // remove this
                      labelPadding: const EdgeInsets.symmetric(vertical: 16), // smaller padding
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Login'),
                        Tab(text: 'Register'),
                      ],
                    ),
                  ),


                  // Tab Views
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginTab(),
                        _buildRegisterTab(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= LOGIN TAB =================
  Widget _buildLoginTab() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20),
        child: Card(
          color: Colors.white10,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 350,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LOGIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: const Color(0xFF2D2A47),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("User ID"),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _apiLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE77FB4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "If you forgot your password, please contact administrator.",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= REGISTER TAB =================
  Widget _buildRegisterTab() {
    return Center(
      child: Card(
        color: Colors.white10,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'REGISTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: const Color(0xFF2D2A47),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(height: 16),

                // Full Name
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Full Name"),
                ),
                const SizedBox(height: 16),

                // Email/UserID
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Email / User ID"),
                ),
                const SizedBox(height: 16),

                // Mobile Number (for all roles)
                TextField(
                  controller: _mobileController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration("Mobile Number"),
                ),
                const SizedBox(height: 16),

                // Student-specific fields
                if (_isStudent) ...[
                  // Enrollment Number
                  TextField(
                    controller: _enrollmentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Enrollment Number"),
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  TextField(
                    controller: _dobController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Date of Birth (YYYY-MM-DD)"),
                  ),
                  const SizedBox(height: 16),

                  // Semester
                  DropdownButtonFormField<String>(
                    value: _selectedSemester.isEmpty ? null : _selectedSemester,
                    dropdownColor: const Color(0xFF2D2A47),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Semester"),
                    items: _semesters
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text("Semester $s"),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSemester = v ?? ''),
                  ),
                  const SizedBox(height: 16),

                  // Department
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                    dropdownColor: const Color(0xFF2D2A47),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Department / Course"),
                    items: _departments
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(_departmentLabels[d] ?? d),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDepartment = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],

                // Visitor-specific fields
                if (_isVisitor) ...[
                  // Purpose of Visit
                  DropdownButtonFormField<String>(
                    value: _selectedPurpose.isEmpty ? null : _selectedPurpose,
                    dropdownColor: const Color(0xFF2D2A47),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Purpose of Visit"),
                    items: _purposes
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(_purposeLabels[p] ?? p),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPurpose = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Confirm Password"),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _apiRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE77FB4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "Registration is for new users. Please fill all fields correctly.",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= API LOGIN (PYTHON + MONGODB) =================
  Future<void> _apiLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final uri = Uri.parse('$kApiBaseUrl/api/login');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': _selectedRole.toLowerCase(),
        }),
      );
      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      }
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic> user = (data['user'] as Map<String, dynamic>?) ?? {};
        final String? token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await AuthService.saveToken(token);
        }
        await AuthService.saveUser(user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful!")),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        final String role = (user['role'] as String? ?? '').toLowerCase();
        switch (role) {
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'faculty':
            Navigator.pushReplacementNamed(context, '/faculty');
            break;
          case 'student':
            Navigator.pushReplacementNamed(
              context,
              '/student',
              arguments: {
                'studentName': user['name'] ?? 'student',
                'semester': '5th Semester',
                'userId': user['_id'] ?? '',
                'email': user['email'] ?? '',
              },
            );
            break;
          case 'visitor':
            Navigator.pushReplacementNamed(context, '/visitor');
            break;
          default:
            Navigator.pushReplacementNamed(
              context,
              '/welcome',
              arguments: {
                'role': role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : 'Student',
                'userId': user['_id'] ?? '',
                'userName': user['name'] ?? 'User',
                'email': user['email'] ?? '',
              },
            );
        }
      } else {
        final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
        final msg = body['message']?.toString() ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (navigator.canPop()) {
        navigator.pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ================= MCA ENROLLMENT VALIDATION =================
  bool isValidMCAEnrollment(String enrollment) {
    // Must be 15 digits
    if (enrollment.length != 15) return false;

    // Must start with fixed prefix
    if (!enrollment.startsWith("202504104610")) return false;

    // Extract last 3 digits
    String serialPart = enrollment.substring(12);
    int? serial = int.tryParse(serialPart);

    if (serial == null) return false;

    // Check range 001 to 174
    if (serial >= 1 && serial <= 174) {
      return true;
    }

    return false;
  }

  // ================= API REGISTER (PYTHON + MONGODB) =================
  Future<void> _apiRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final mobile = _mobileController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    // Role-specific validation
    if (_isStudent) {
      final enrollment = _enrollmentController.text.trim();
      final dob = _dobController.text.trim();
      
      if (enrollment.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter enrollment number")),
        );
        return;
      }

      // Validate MCA enrollment numbers
      if (_selectedDepartment == 'mca') {
        if (!isValidMCAEnrollment(enrollment)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid MCA Enrollment Number. Must be between 202504104610006 and 202504104610174")),
          );
          return;
        }
      }

      if (dob.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter date of birth")),
        );
        return;
      }
      if (_selectedSemester.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select semester")),
        );
        return;
      }
      if (_selectedDepartment.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select department")),
        );
        return;
      }
    }

    if (_isVisitor) {
      if (mobile.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter mobile number")),
        );
        return;
      }
      if (_selectedPurpose.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select purpose of visit")),
        );
        return;
      }
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    // Build request body based on role
    final Map<String, dynamic> requestBody = {
      'name': name,
      'email': email,
      'password': password,
      'role': _selectedRole.toLowerCase(),
      'mobile': mobile,
    };

    // Add student-specific fields
    if (_isStudent) {
      requestBody['enrollment'] = _enrollmentController.text.trim();
      requestBody['dob'] = _dobController.text.trim();
      requestBody['semester'] = _selectedSemester;
      requestBody['department'] = _selectedDepartment;
    }

    // Add visitor-specific fields
    if (_isVisitor) {
      requestBody['purpose'] = _selectedPurpose;
    }

    try {
      final uri = Uri.parse('$kApiBaseUrl/api/register');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      // Close dialog if still open
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful! Please login.")),
        );

        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _nameController.clear();

        _tabController.animateTo(0);
      } else {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final msg = body['message']?.toString() ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Close dialog if still open
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ================= COMMON INPUT STYLE =================
  InputDecoration _inputDecoration([String? hint]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
