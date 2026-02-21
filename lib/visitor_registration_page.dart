import 'package:flutter/material.dart';
import 'VisitorHomePage.dart';

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
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedPurpose = 'General Inquiry';
  
  final List<String> _purposes = [
    'General Inquiry',
    'Admission Query',
    'Parent Meeting',
    'Guest Lecture',
    'Corporate Visit',
    'Research Discussion',
    'Partnership Proposal',
    'Other',
  ];

  bool _isLoading = false;

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      
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
              const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: accentBlue),
                  hintText: "Enter your full name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentBlue, width: 2)),
                ),
                validator: (value) => value == null || value.isEmpty ? "Please enter your name" : null,
              ),

              const SizedBox(height: 16),

              // Mobile Field
              const Text("Mobile Number", style: TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: accentBlue),
                  hintText: "Enter your mobile number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentBlue, width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter your mobile number";
                  if (value.length < 10) return "Please enter a valid mobile number";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email Field
              const Text("Email Address", style: TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: accentBlue),
                  hintText: "Enter your email address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentBlue, width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter your email";
                  if (!value.contains('@')) return "Please enter a valid email";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Purpose Dropdown
              const Text("Purpose of Visit", style: TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPurpose,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.flag, color: accentBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentBlue, width: 2)),
                ),
                items: _purposes.map((purpose) => DropdownMenuItem(value: purpose, child: Text(purpose))).toList(),
                onChanged: (value) => setState(() => _selectedPurpose = value!),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
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
                      : const Text("Submit Registration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Center(
                child: Text(
                  "Your information will be reviewed by college admin.\nYou will receive a confirmation once approved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
