import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= VISITOR MODEL =================
class Visitor {
  String id;
  String name;
  String email;
  String phone;
  String visitPurpose;
  String visitDate;
  String status;

  Visitor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.visitPurpose,
    required this.visitDate,
    required this.status,
  });

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      visitPurpose: map['visit_purpose'] ?? '',
      visitDate: map['visit_date'] ?? '',
      status: map['status'] ?? 'Pending',
    );
  }
}

/// ================= VISITOR MANAGEMENT PAGE =================
class VisitorManagementPage extends StatefulWidget {
  const VisitorManagementPage({super.key});

  @override
  State<VisitorManagementPage> createState() => _VisitorManagementPageState();
}

class _VisitorManagementPageState extends State<VisitorManagementPage> {
  List<Visitor> visitors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    try {
      // Mock data for visitors
      setState(() {
        visitors = [
          Visitor(id: '1', name: 'John Doe', email: 'john@example.com', phone: '1234567890', visitPurpose: 'Admission Inquiry', visitDate: '2024-01-15', status: 'Approved'),
          Visitor(id: '2', name: 'Jane Smith', email: 'jane@example.com', phone: '9876543210', visitPurpose: 'Parent Meeting', visitDate: '2024-01-16', status: 'Pending'),
          Visitor(id: '3', name: 'Bob Wilson', email: 'bob@example.com', phone: '5555555555', visitPurpose: 'Campus Tour', visitDate: '2024-01-17', status: 'Completed'),
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        visitors = [];
        isLoading = false;
      });
    }
  }

  String searchQuery = "";

  List<Visitor> get filteredVisitors {
    if (searchQuery.isEmpty) return visitors;
    return visitors
        .where((v) =>
            v.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            v.email.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor Management"),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search visitors...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredVisitors.length,
                      itemBuilder: (context, index) {
                        final visitor = filteredVisitors[index];
                        Color statusColor;
                        switch (visitor.status) {
                          case 'Approved':
                            statusColor = Colors.green;
                            break;
                          case 'Pending':
                            statusColor = Colors.orange;
                            break;
                          case 'Completed':
                            statusColor = Colors.blue;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1A237E),
                              child: Text(visitor.name[0], style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(visitor.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(visitor.email),
                                Text("${visitor.visitPurpose} | ${visitor.visitDate}"),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(visitor.status, style: const TextStyle(color: Colors.white)),
                              backgroundColor: statusColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
