import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= FACULTY MODEL =================
class Faculty {
  String id;
  String name;
  String email;
  String department;
  String designation;
  String status;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    required this.status,
  });

  factory Faculty.fromMap(Map<String, dynamic> map) {
    return Faculty(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      designation: map['designation'] ?? '',
      status: map['is_active'] == true ? 'Active' : 'Inactive',
    );
  }
}

/// ================= FACULTY MANAGEMENT PAGE =================
class FacultyManagementPage extends StatefulWidget {
  const FacultyManagementPage({super.key});

  @override
  State<FacultyManagementPage> createState() => _FacultyManagementPageState();
}

class _FacultyManagementPageState extends State<FacultyManagementPage> {
  List<Faculty> faculty = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  Future<void> _loadFaculty() async {
    try {
      final facultyData = await ApiService.getUsers();
      setState(() {
        faculty = facultyData
            .where((u) => u['role'] == 'faculty')
            .map((u) => Faculty.fromMap(u))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        faculty = [];
        isLoading = false;
      });
    }
  }

  String searchQuery = "";

  List<Faculty> get filteredFaculty {
    if (searchQuery.isEmpty) return faculty;
    return faculty
        .where((f) =>
            f.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            f.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
            f.department.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Management"),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search faculty...",
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
                      itemCount: filteredFaculty.length,
                      itemBuilder: (context, index) {
                        final member = filteredFaculty[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1A237E),
                              child: Text(member.name[0], style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(member.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.email),
                                Text("${member.department} | ${member.designation}"),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(member.status),
                              backgroundColor: member.status == 'Active' ? Colors.green : Colors.red,
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
