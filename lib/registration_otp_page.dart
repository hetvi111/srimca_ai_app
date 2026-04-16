import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:srimca_ai/static_data.dart';

class RegistrationOtpPage extends StatefulWidget {
  final String email;
  final String name;
  final Map<String, dynamic> registrationBody;

  const RegistrationOtpPage({
    super.key,
    required this.email,
    required this.name,
    required this.registrationBody,
  });

  @override
  State<RegistrationOtpPage> createState() => _RegistrationOtpPageState();
}

class _RegistrationOtpPageState extends State<RegistrationOtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpVerified = false;
  DateTime? _lastResendTime;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _sendEmailOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.sendRegistrationOtp(
        email: widget.email,
        name: widget.name,
      );
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to ${widget.email}')),
        );
        _lastResendTime = DateTime.now();
        _startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to send OTP')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _startResendTimer() {
    _canResend = false;
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    await _sendEmailOtp();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.verifyRegistrationOtp(
        email: widget.email,
        otp: otp,
      );
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _isOtpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Invalid OTP')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completeRegistration() async {
    if (!_isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify OTP first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('$kApiBaseUrl/api/register');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(widget.registrationBody),
      );

      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((body['error'] ?? 'Registration failed').toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getResendText() {
    if (_canResend) return 'Resend OTP';
    final secondsLeft = 60 - DateTime.now().difference(_lastResendTime!).inSeconds;
    return 'Resend in ${secondsLeft}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We sent a 6-digit OTP to ${widget.email}. Enter it to complete registration.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: const Text('Verify OTP'),
            ),
            TextButton(
              onPressed: _isLoading || !_canResend ? null : _resendOtp,
              child: Text(_getResendText()),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _completeRegistration,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isOtpVerified ? 'Complete Registration' : 'Verify OTP to Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

