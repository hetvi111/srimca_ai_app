import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

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
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    try {
      final data = await ApiService.getFacultyVisitorInquiries();
      if (!mounted) return;
      setState(() {
        visitors = data;
        isLoading = false;
      });
      for (final visitor in data) {
        final id = (visitor['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        _replyControllers.putIfAbsent(
          id,
          () => TextEditingController(text: (visitor['faculty_reply'] ?? '').toString()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        visitors = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load visitor inquiries: $e')),
      );
    }
  }

  Future<void> _updateStatus(String visitorId, String newStatus) async {
    final reply = _replyControllers[visitorId]?.text.trim() ?? '';
    final ok = await ApiService.respondFacultyVisitorInquiry(
      visitorId: visitorId,
      status: newStatus,
      facultyReply: reply,
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update visitor inquiry')),
      );
      return;
    }

    setState(() {
      visitors = visitors.map((v) {
        if ((v['_id'] ?? '').toString() == visitorId) {
          return {
            ...v,
            'status': newStatus,
            'approval_status': newStatus,
            'faculty_reply': reply,
          };
        }
        return v;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visitor request ${newStatus.toUpperCase()} and reply saved')),
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
    final status = (visitor['status'] ?? visitor['approval_status'] ?? 'pending').toString().toLowerCase();
    final visitorId = (visitor['_id'] ?? visitor['id'] ?? '').toString();
    final visitDate = (visitor['visit_date'] ?? visitor['visitDate'] ?? '').toString();
    final question = (visitor['question'] ?? visitor['purpose'] ?? '').toString();
    final purpose = (visitor['purpose'] ?? '').toString();
    final replyController = _replyControllers.putIfAbsent(
      visitorId,
      () => TextEditingController(text: (visitor['faculty_reply'] ?? '').toString()),
    );
    
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
                      Text(purpose, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                _buildDetailRow(Icons.calendar_today, "Visit Date", visitDate),
                _buildDetailRow(Icons.phone, "Phone", visitor['phone'] ?? ''),
                _buildDetailRow(Icons.email, "Email", visitor['email'] ?? ''),
                _buildDetailRow(Icons.help_outline, "Visitor Question", question),
                const SizedBox(height: 10),
                TextField(
                  controller: replyController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reply Message',
                    hintText: 'Type your answer for this visitor inquiry',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: visitorId.isEmpty ? null : () => _updateStatus(visitorId, 'rejected'),
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
                          onPressed: visitorId.isEmpty ? null : () => _updateStatus(visitorId, 'approved'),
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
                      onPressed: visitorId.isEmpty ? null : () => _updateStatus(visitorId, 'completed'),
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

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
