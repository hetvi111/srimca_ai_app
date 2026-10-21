import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= STUDENT MODEL =================
class Student {
  String id;
  String name;
  String email;
  String enrollmentNumber;
  String semester;
  String course;
  String status;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.semester,
    required this.course,
    required this.status,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      enrollmentNumber: map['enrollment_number'] ?? '',
      semester: map['semester'] ?? '',
      course: map['course'] ?? '',
      status: map['is_active'] == true ? 'Active' : 'Inactive',
    );
  }
}

/// ================= STUDENT MANAGEMENT PAGE =================
class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  List<Student> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final studentsData = await ApiService.getUsers();
      setState(() {
        students = studentsData
            .where((u) => u['role'] == 'student')
            .map((u) => Student.fromMap(u))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        students = [];
        isLoading = false;
      });
    }
  }

  String searchQuery = "";

  List<Student> get filteredStudents {
    if (searchQuery.isEmpty) return students;
    return students
        .where((s) =>
            s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            s.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
            s.enrollmentNumber.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management"),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search students...",
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
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1A237E),
                              child: Text(student.name[0], style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(student.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.email),
                                Text("Enroll: ${student.enrollmentNumber} | Sem: ${student.semester}"),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(student.status),
                              backgroundColor: student.status == 'Active' ? Colors.green : Colors.red,
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
