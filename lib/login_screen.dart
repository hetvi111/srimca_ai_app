import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/push_notification_service.dart';

class LoginScreen extends StatefulWidget {
  final String? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Theme Colors
  static const Color navyDark = Color(0xFF001F3F);
  static const Color navyMedium = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color lightIndigo = Color(0xFF3949AB);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('$kApiBaseUrl/api/login');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
        final Map<String, dynamic> user = (data['user'] as Map<String, dynamic>?) ?? {};
        final String? token = data['token'] as String?;

        if (token != null && token.isNotEmpty) {
          await AuthService.saveToken(token);
        }
        await AuthService.saveUser(user);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Successful! Welcome back."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final String role = (user['role'] as String? ?? '').toLowerCase();

        // Subscribe to role-based notifications
        try {
          if (role.isNotEmpty && !kIsWeb) {
            await PushNotificationService.subscribeToRoleTopics(role);
          }
        } catch (e) {
          debugPrint('FCM topic subscription notice: $e');
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
                'semester': user['semester'] ?? 'semester',
                'userId': user['_id'] ?? '',
                'email': user['email'] ?? '',
                'enrollmentNumber': user['enrollment'] ?? user['enrollment_number'] ?? '',
                'course': user['department'] ?? user['course'] ?? '',
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
        final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
        final msg = body['error']?.toString() ??
            body['message']?.toString() ??
            'Invalid email or password';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: Unable to reach server ($e)'),
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar with back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                        tooltip: 'Back to Home',
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/first');
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // App Logo & Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 70,
                          width: 70,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.smart_toy_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Sign in to access SRIMCA AI Assistant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Card
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
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Email Address',
                                hint: 'example@srimca.edu',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Password',
                                hint: 'Enter your password',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white60,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot-password');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF64B5F6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Sign In Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
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
                                        'Sign In',
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

                    // Quick Visitor Entry Pass Link
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded, color: Colors.amberAccent, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Are you a campus visitor?',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/visitor-entry');
                            },
                            child: const Text(
                              'QR Entry',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer -> Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/register');
                          },
                          child: const Text(
                            'Create Account',
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
