import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/api_service.dart';
import 'dart:convert';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class VisitorProfilePage extends StatefulWidget {
  final String? visitorId;
  
  const VisitorProfilePage({super.key, this.visitorId});

  @override
  State<VisitorProfilePage> createState() => _VisitorProfilePageState();
}

class _VisitorProfilePageState extends State<VisitorProfilePage> {
  // Visitor data from database
  Map<String, dynamic> visitorData = {};
  List<Map<String, dynamic>> visitHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitorData();
  }

  Future<void> _loadVisitorData() async {
    try {
      // Get stored user data
      final userData = await ApiService.getUser();
      
      if (userData != null && userData.isNotEmpty) {
        if (mounted) {
          setState(() {
            visitorData = {
              'name': userData['name'] ?? 'Visitor',
              'email': userData['email'] ?? '',
              'phone': userData['mobile'] ?? userData['phone'] ?? '',
              'purpose': userData['purpose'] ?? 'Not specified',
              'status': userData['status'] ?? 'pending',
              'registrationDate': _formatDate(userData['created_at'] ?? userData['registrationDate']),
            };
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading visitor data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      if (dateStr is String) {
        return dateStr.substring(0, 10);
      }
      return dateStr.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("My Profile"),
          backgroundColor: navyBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVisitorData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [navyBlue, navyBlueLight]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: navyBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitorData['name'] ?? 'Visitor',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(visitorData['status']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            visitorData['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: TextStyle(color: _getStatusColor(visitorData['status']), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Information
            _sectionTitle("Contact Information"),
            const SizedBox(height: 12),
            _infoCard([
              _infoRow(Icons.person, "Name", visitorData['name'] ?? 'N/A'),
              _infoRow(Icons.phone, "Phone", visitorData['phone'] ?? 'N/A'),
              _infoRow(Icons.email, "Email", visitorData['email'] ?? 'N/A'),
              _infoRow(Icons.flag, "Purpose", visitorData['purpose'] ?? 'N/A'),
              _infoRow(Icons.calendar_today, "Registered On", visitorData['registrationDate'] ?? 'N/A'),
            ]),

            const SizedBox(height: 24),

            // Update Profile Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: accentBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _showUpdateDialog();
                },
                icon: const Icon(Icons.edit, color: accentBlue),
                label: const Text("Update Profile", style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 24),

            // Visit History
            _sectionTitle("Visit History"),
            const SizedBox(height: 12),
            
            if (visitHistory.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text("No visit history", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
            else
              ...visitHistory.map((visit) => _visitHistoryCard(visit)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentBlue),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitHistoryCard(Map<String, dynamic> visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(visit['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event, color: _getStatusColor(visit['status'])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit['purpose'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: navyBlue)),
                Text(visit['department'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(visit['date'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(visit['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              visit['status']?.toString().toUpperCase() ?? '',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(visit['status'])),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'completed': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showUpdateDialog() {
    final nameController = TextEditingController(text: visitorData['name'] ?? '');
    final phoneController = TextEditingController(text: visitorData['phone'] ?? '');
    final emailController = TextEditingController(text: visitorData['email'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Update Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyBlue)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    // Update local data (in production, call API to update)
                    setState(() {
                      visitorData['name'] = nameController.text;
                      visitorData['phone'] = phoneController.text;
                      visitorData['email'] = emailController.text;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
