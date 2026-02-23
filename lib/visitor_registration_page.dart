import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'VisitorHomePage.dart';
import 'api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class VisitorRegistrationPage extends StatefulWidget {
  const VisitorRegistrationPage({super.key});

  @override
  State<VisitorRegistrationPage> createState() => _VisitorRegistrationPageState();
}

class _VisitorRegistrationPageState extends State<VisitorRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Visitor fields
  String _selectedPurpose = '';
  
  final List<String> _purposes = [
    'admission',
    'placement',
    'meeting',
    'event',
    'tour',
    'other',
  ];
  
  final Map<String, String> _purposeLabels = {
    'admission': 'Admission Inquiry',
    'placement': 'Placement/Recruitment',
    'meeting': 'Meeting with Faculty',
    'event': 'College Event',
    'tour': 'Campus Tour',
    'other': 'Other',
  };
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build request body for visitor registration
      final Map<String, dynamic> requestBody = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text,
        'role': 'visitor',
        'mobile': _mobileController.text.trim(),
        'purpose': _selectedPurpose,
      };
      
      // Call backend API
      final uri = Uri.parse('$kApiBaseUrl/api/register');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (res.statusCode == 201) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 12),
                Text("Registration Successful!"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Thank you for registering! Your visit request has been submitted."),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: accentBlue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You will receive a confirmation notification once your visit is approved.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const VisitorHomePage()),
                  );
                },
                child: const Text("Continue"),
              ),
            ],
          ),
        );
      } else {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final msg = body['error']?.toString() ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Visitor Registration"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [navyBlue, navyBlueLight]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Register Your Visit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Fill in your details below", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                icon: Icons.person,
                hint: "Enter your full name",
                validator: (value) => value == null || value.isEmpty ? "Please enter your name" : null,
              ),

              const SizedBox(height: 16),

              // Mobile Field
              _buildTextField(
                controller: _mobileController,
                label: "Mobile Number",
                icon: Icons.phone,
                hint: "Enter your mobile number",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter your mobile number";
                  if (value.length < 10) return "Please enter a valid mobile number";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email,
                hint: "Enter your email address",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter your email";
                  if (!value.contains('@')) return "Please enter a valid email";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Purpose Dropdown
              _buildDropdown(
                label: "Purpose of Visit",
                icon: Icons.flag,
                value: _selectedPurpose,
                items: _purposes,
                onChanged: (value) => setState(() => _selectedPurpose = value!),
                validator: (value) => value == null || value.isEmpty ? "Please select purpose of visit" : null,
              ),

              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                icon: Icons.lock,
                hint: "Create password (min 6 chars)",
                obscure: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter password";
                  if (value.length < 6) return "Password must be at least 6 characters";
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 16),

              // Info Text
              _buildInfoText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accentBlue),
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentBlue, width: 2),
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accentBlue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentBlue, width: 2),
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(itemLabels?[item] ?? item),
          )).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _submitRegistration,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : const Text(
                "Submit Registration",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Center(
      child: Text(
        "Your information will be reviewed by college admin.\nYou will receive a confirmation once approved.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }
}
