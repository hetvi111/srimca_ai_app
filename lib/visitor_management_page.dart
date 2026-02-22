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
      // Fetch visitors from API
      final visitorsData = await ApiService.getVisitors();
      setState(() {
        visitors = visitorsData.map((v) => Visitor.fromMap(v)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        visitors = [];
        isLoading = false;
      });
    }
  }

  Future<void> _updateVisitorStatus(String visitorId, String newStatus) async {
    final success = await ApiService.updateVisitorStatus(visitorId, newStatus);
    if (success) {
      setState(() {
        final index = visitors.indexWhere((v) => v.id == visitorId);
        if (index != -1) {
          visitors[index] = Visitor(
            id: visitors[index].id,
            name: visitors[index].name,
            email: visitors[index].email,
            phone: visitors[index].phone,
            visitPurpose: visitors[index].visitPurpose,
            visitDate: visitors[index].visitDate,
            status: newStatus,
          );
        }
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
