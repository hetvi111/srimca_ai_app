import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= USER MODEL =================
class User {
  String id;
  String name;
  String email;
  String role;
  String status;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      status: map['is_active'] == true ? 'Active' : 'Inactive',
    );
  }
}

/// ================= USER MANAGEMENT PAGE =================
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    // Fetch users from backend API
    try {
      final usersData = await ApiService.getUsers();
      setState(() {
        users = usersData.map((u) => User.fromMap(u)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        users = [];
        isLoading = false;
      });
    }
  }

  String selectedRole = "All";
  String searchQuery = "";

  /// ================= FILTER USERS =================
  List<User> get filteredUsers {
    var tempUsers = users;
    if (selectedRole != "All") {
      tempUsers = tempUsers.where((u) => u.role == selectedRole).toList();
    }
    if (searchQuery.isNotEmpty) {
      tempUsers = tempUsers
          .where((u) =>
      u.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    return tempUsers;
  }

  /// ================= ADD USER =================
  Future<void> addUser(String name, String email, String role) async {
    // TODO: Implement API call to add user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add user functionality requires backend')),
    );
  }

  /// ================= DELETE USER =================
  Future<void> deleteUser(String id) async {
    // Call API to deactivate user
    final success = await ApiService.deactivateUser(id);
    if (success) {
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to deactivate user')),
        );
      }
    }
  }

  /// ================= TOGGLE STATUS =================
  Future<void> toggleStatus(User user) async {
    if (user.status == 'Active') {
      final success = await ApiService.deactivateUser(user.id);
      if (success) {
        setState(() {
          user.status = 'Inactive';
        });
      }
    } else {
      final success = await ApiService.activateUser(user.id);
      if (success) {
        setState(() {
          user.status = 'Active';
        });
      }
    }
  }

  /// ================= EDIT USER =================
  void editUser(User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String role = user.role;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            DropdownButtonFormField(
              value: role,
              items: ["Admin", "Faculty", "Student"]
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) => role = value!,
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  user.name = nameCtrl.text;
                  user.email = emailCtrl.text;
                  user.role = role;
                });
                Navigator.pop(context);
              },
              child: const Text("Save")),
        ],
      ),
    );
  }

  /// ================= ADD USER DIALOG =================
  void showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = "Student";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            DropdownButtonFormField(
              value: role,
              items: ["Admin", "Faculty", "Student"]
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) => role = value!,
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  addUser(nameCtrl.text, emailCtrl.text, role);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add")),
        ],
      ),
    );
  }

 /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Management",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [IconButton(onPressed: showAddUserDialog, icon: const Icon(Icons.add))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// ================= SEARCH + FILTER ROW =================
            Row(
              children: [
                /// Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search by name or email",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                /// Role Filter
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField(
                    value: selectedRole,
                    items: ["All", "Admin", "Faculty", "Student"]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Role",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ================= USER LIST =================
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Scrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(user.name[0]),
                      ),
                      title: Text(user.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text("Role: ${user.role}"),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => toggleStatus(user),
                            child: Text(
                              user.status,
                              style: TextStyle(
                                color: user.status == "Active" ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => editUser(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => deleteUser(user.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
