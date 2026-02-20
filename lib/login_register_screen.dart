import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:srimca_ai/static_data.dart';
import 'package:srimca_ai/api_service.dart';

// TODO: Replace with your deployed Python backend URL (Flask + MongoDB Atlas)
// For local development: 'http://172.31.229.182:5000' or 'http://10.0.2.2:5000' (Android emulator)
// For production: Use your Render.com URL (e.g., 'https://srimca-ai-backend.onrender.com')
// Set to false for production, true for local development
const bool kUseLocalDev = false;

String get kApiBaseUrl => kUseLocalDev 
  ? 'http://172.31.229.182:5000' 
  : 'https://srimca-ai-backend.onrender.com';

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

    // Show loading dialog
    if (!mounted) return;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uri = Uri.parse('$kApiBaseUrl/api/login');
      
      // Add timeout to prevent hanging
      final client = http.Client();
      http.Response res;
      try {
        res = await client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        ).timeout(const Duration(seconds: 10));
      } finally {
        client.close();
      }

      if (!mounted) return;
      // Close dialog before navigation - use stored navigator
      if (navigator.canPop()) {
        navigator.pop();
        // Small delay to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        
        // Check if user data exists in response
        if (body['user'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid response from server")),
          );
          return;
        }
        
        final Map<String, dynamic> user = body['user'] as Map<String, dynamic>;
        
        // Save token and user data for API calls
        if (body['token'] != null) {
          await AuthService.saveToken(body['token'] as String);
        }
        await AuthService.saveUser(user);
        
        // Check if role exists
        if (user['role'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User role not found")),
          );
          return;
        }
        
        final String role = (user['role'] as String).toLowerCase();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful!")),
        );

        // Small delay to allow snackbar to show before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        switch (role) {
          case 'admin':
            print('DEBUG: Navigating to /admin');
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'faculty':
            print('DEBUG: Navigating to /faculty');
            Navigator.pushReplacementNamed(context, '/faculty');
            break;
          case 'student':
            print('DEBUG: Navigating to /student with args: ${user['name']}');
            // Navigate directly to student page with correct arguments
            Navigator.pushReplacementNamed(
              context,
              '/student',
              arguments: {
                'studentName': user['name'] ?? 'student',
                'semester': '5th Semester', // Default semester, can be updated from user data
                'userId': user['_id'] ?? '',
                'email': user['email'] ?? '',
              },
            );
            break;
          case 'visitor':
            print('DEBUG: Navigating to /visitor');
            Navigator.pushReplacementNamed(context, '/visitor');
            break;
          default:
            print('DEBUG: Unknown role "$role", navigating to /welcome');
            // fallback - navigate to welcome screen
            Navigator.pushReplacementNamed(
              context,
              '/welcome',
              arguments: {
                'role': role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : 'student',
                'userId': user['_id'] ?? '',
                'userName': user['name'] ?? 'User',
                'email': user['email'] ?? '',
              },
            );
        }
      } else {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final msg = body['message']?.toString() ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ================= API REGISTER (PYTHON + MONGODB) =================
  Future<void> _apiRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
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

    try {
      final uri = Uri.parse('$kApiBaseUrl/api/register');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': _selectedRole.toLowerCase(), // student/faculty/admin/visitor
        }),
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
