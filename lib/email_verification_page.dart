import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/firebase_service.dart';

/// Email verification page - matches app theme (navy gradient, white cards)
/// Supports: 1) Email+password verification (from registration) 2) Magic link
class EmailVerificationPage extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;
  final VoidCallback? onVerified;

  const EmailVerificationPage({
    super.key,
    this.initialEmail,
    this.initialPassword,
    this.onVerified,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  bool _useMagicLink = false;
  String? _errorMessage;
  String? _successMessage;

  static const String _emailForLinkKey = 'email_for_sign_in_link';

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _passwordController.text = widget.initialPassword ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (_useMagicLink) {
      const projectId = 'srimcaai';
      final continueUrl =
          'https://$projectId.firebaseapp.com/__/auth/action';
      final result = await FirebaseService.sendSignInLinkToEmail(
        email: email,
        continueUrl: continueUrl,
      );
      if (result['success'] == true && mounted) {
        await SharedPreferences.getInstance().then((prefs) {
          prefs.setString(_emailForLinkKey, email);
        });
        setState(() {
          _emailSent = true;
          _successMessage =
              'Verification link sent! Check your inbox and tap the link to verify.';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] as String? ?? 'Failed to send';
            _isLoading = false;
          });
        }
      }
    } else {
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your password';
          _isLoading = false;
        });
        return;
      }
      final result = await FirebaseService.sendVerificationForEmail(
        email: email,
        password: password,
      );
      if (result['success'] == true && mounted) {
        setState(() {
          _emailSent = true;
          _successMessage =
              'Verification email sent! Check your inbox and click the link, then tap below.';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] as String? ?? 'Failed to send';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final verified = await FirebaseService.checkEmailVerified();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (verified) {
      setState(() {
        _successMessage = 'Email verified successfully!';
        _errorMessage = null;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onVerified?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _errorMessage =
            'Not verified yet. Please click the link in your email first.';
      });
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF22365E),
              Color(0xFF3949AB),
              Color(0xFF1E88E5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 72,
                  color: Colors.white.withOpacity(0.95),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Email Verification',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your email to secure your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 32),

                Card(
                  color: Colors.white10,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Email'),
                          enabled: !_emailSent,
                        ),
                        const SizedBox(height: 16),

                        if (!_useMagicLink) ...[
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Password'),
                            enabled: !_emailSent,
                          ),
                          const SizedBox(height: 16),
                        ],

                        SwitchListTile(
                          value: _useMagicLink,
                          onChanged: _emailSent
                              ? null
                              : (v) => setState(() => _useMagicLink = v),
                          title: const Text(
                            'Use magic link (no password)',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          activeColor: const Color(0xFF1E88E5),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_successMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.greenAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (!_emailSent)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendVerificationEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Send Verification Email',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          )
                        else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _checkVerification,
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.verified_user, size: 20),
                              label: Text(
                                _isLoading
                                    ? 'Checking...'
                                    : "I've verified my email",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _emailSent = false;
                                      _successMessage = null;
                                      _errorMessage = null;
                                    });
                                  },
                            child: const Text(
                              'Resend verification email',
                              style: TextStyle(
                                color: Color(0xFF1E88E5),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Check your spam folder if you don\'t see the email',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
