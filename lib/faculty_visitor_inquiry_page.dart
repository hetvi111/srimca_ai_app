import 'package:flutter/material.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class FacultyVisitorInquiryPage extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String department;
  
  const FacultyVisitorInquiryPage({
    super.key,
    required this.facultyId,
    required this.facultyName,
    required this.department,
  });

  @override
  State<FacultyVisitorInquiryPage> createState() => _FacultyVisitorInquiryPageState();
}

class _FacultyVisitorInquiryPageState extends State<FacultyVisitorInquiryPage> {
  List<Map<String, dynamic>> visitors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        visitors = _getDemoVisitors();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDemoVisitors() {
    return [
      {
        'id': '1',
        'name': 'John Smith',
        'purpose': 'Guest Lecture Inquiry',
        'department': widget.department,
        'visitDate': '2024-02-25',
        'status': 'pending',
        'phone': '+91 9876543210',
        'email': 'john.smith@example.com',
      },
      {
        'id': '2',
        'name': 'Dr. Sarah Johnson',
        'purpose': 'Academic Collaboration',
        'department': widget.department,
        'visitDate': '2024-02-28',
        'status': 'approved',
        'phone': '+91 9876543211',
        'email': 'sarah.j@mit.edu',
      },
      {
        'id': '3',
        'name': 'Michael Brown',
        'purpose': 'Workshop Proposal',
        'department': widget.department,
        'visitDate': '2024-03-01',
        'status': 'pending',
        'phone': '+91 9876543212',
        'email': 'michael.brown@example.com',
      },
      {
        'id': '4',
        'name': 'Emily Davis',
        'purpose': 'Research Discussion',
        'department': widget.department,
        'visitDate': '2024-02-15',
        'status': 'completed',
        'phone': '+91 9876543213',
        'email': 'emily.d@stanford.edu',
      },
    ];
  }

  Future<void> _updateStatus(String visitorId, String newStatus) async {
    setState(() {
      visitors = visitors.map((v) {
        if (v['id'] == visitorId) {
          return {...v, 'status': newStatus};
        }
        return v;
      }).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visitor request ${newStatus}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Visitor Inquiries"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : visitors.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVisitors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final visitor = visitors[index];
                      return _buildVisitorCard(visitor);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No Visitor Inquiries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("Visitor requests will appear here", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildVisitorCard(Map<String, dynamic> visitor) {
    final status = visitor['status'] ?? 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(Icons.person, color: _getStatusColor(status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visitor['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyBlue)),
                      Text(visitor['purpose'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.badge, "Department", visitor['department'] ?? ''),
                _buildDetailRow(Icons.calendar_today, "Visit Date", visitor['visitDate'] ?? ''),
                _buildDetailRow(Icons.phone, "Phone", visitor['phone'] ?? ''),
                _buildDetailRow(Icons.email, "Email", visitor['email'] ?? ''),
                const SizedBox(height: 12),
                // Action buttons
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(visitor['id'], 'rejected'),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(visitor['id'], 'approved'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  ),
                if (status == 'approved')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(visitor['id'], 'completed'),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark as Completed'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: navyBlue)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
