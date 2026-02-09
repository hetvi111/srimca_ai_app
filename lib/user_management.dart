import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// For Android Emulator: use 'http://10.0.2.2:5000'
// For Real Phone: use your computer's local IP (run 'ipconfig' on Windows)
// Example: const String baseUrl = 'http://192.168.1.100:5000';
//const String baseUrl = 'http://10.27.15.181:5000';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const UserManagementPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// User Model
class User {
  final String id;
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
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  int currentPage = 1;
  String selectedRole = 'All Roles';
  String searchQuery = '';
  Set<String> selectedUsers = {};
  bool isLoading = true;

  List<User> allUsers = [];
  List<User> filteredUsers = [];
  final int itemsPerPage = 4;

 final String backendUrl = "http://10.27.15.181:5000";


  @override
  void initState() {
    super.initState();
    filteredUsers = [];
    fetchUsers();
  }

  void filterUsers() {
    setState(() {
      filteredUsers = allUsers.where((user) {
        final matchesSearch = user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesRole = selectedRole == 'All Roles' || user.role == selectedRole;
        return matchesSearch && matchesRole;
      }).toList();
      currentPage = 1;
    });
  }

  int getTotalPages() {
    if (filteredUsers.isEmpty) return 1;
    return (filteredUsers.length / itemsPerPage).ceil();
  }

  List<User> getPaginatedUsers() {
    if (filteredUsers.isEmpty) return [];

    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= filteredUsers.length) return [];

    final endIndex = startIndex + itemsPerPage;
    return filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );
  }

  Color getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFF3B82F6);
      case 'Faculty':
        return const Color(0xFF14B8A6);
      case 'Student':
        return const Color(0xFF8B9DC3);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile settings')),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 500;

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Manage Users', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Add, edit, or manage user accounts', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _showAddUserDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add User'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E40AF),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Manage Users', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Add, edit, or manage user accounts', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () => _showAddUserDialog(context),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add User'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E40AF),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      searchQuery = value;
                      filterUsers();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() => selectedRole = value);
                            filterUsers();
                          },
                          itemBuilder: (BuildContext context) {
                            return ['All Roles', 'Admin', 'Faculty', 'Student'].map((String role) {
                              return PopupMenuItem<String>(value: role, child: Text(role));
                            }).toList();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.filter_list, color: Color(0xFF1E40AF), size: 18),
                                const SizedBox(width: 6),
                                const Text('Filters', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, color: Colors.grey.shade600, size: 18),
                              const SizedBox(width: 4),
                              Text(selectedRole, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 12)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            _handleBulkAction(value);
                          },
                          itemBuilder: (BuildContext context) {
                            return ['Delete Selected', 'Export Selected', 'Change Role'].map((String action) {
                              return PopupMenuItem<String>(value: action, child: Text(action));
                            }).toList();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Bulk Actions', style: TextStyle(color: const Color(0xFF1E40AF), fontWeight: FontWeight.w600, fontSize: 12)),
                                Icon(Icons.arrow_drop_down, color: const Color(0xFF1E40AF), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Users Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Checkbox(
                              value: selectedUsers.length == getPaginatedUsers().length && getPaginatedUsers().isNotEmpty,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedUsers = {for (var user in getPaginatedUsers()) user.id};
                                  } else {
                                    selectedUsers.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(width: 150, child: _buildTableHeader('Name')),
                          const SizedBox(width: 12),
                          SizedBox(width: 180, child: _buildTableHeader('Email')),
                          const SizedBox(width: 12),
                          SizedBox(width: 100, child: _buildTableHeader('Role')),
                          const SizedBox(width: 12),
                          SizedBox(width: 100, child: _buildTableHeader('Status')),
                          const SizedBox(width: 12),
                          SizedBox(width: 140, child: _buildTableHeader('Actions')),
                        ],
                      ),
                    ),
                    ...getPaginatedUsers().map((user) {
                      return _buildUserRow(user);
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Pagination
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                        ),
                        ...List.generate(getTotalPages(), (index) {
                          final pageNumber = index + 1;
                          return GestureDetector(
                            onTap: () => setState(() => currentPage = pageNumber),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentPage == pageNumber ? const Color(0xFF3B82F6) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(pageNumber.toString(), style: TextStyle(color: currentPage == pageNumber ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          );
                        }),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage < getTotalPages() ? () => setState(() => currentPage++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Showing ${(currentPage - 1) * itemsPerPage + 1} to ${(currentPage - 1) * itemsPerPage + getPaginatedUsers().length} of ${filteredUsers.length}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (title == 'Name') const SizedBox(width: 4),
        if (title == 'Name') const Icon(Icons.arrow_upward, size: 12, color: Colors.grey),
      ],
    );
  }

  Widget _buildUserRow(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            child: Checkbox(
              value: selectedUsers.contains(user.id),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedUsers.add(user.id);
                  } else {
                    selectedUsers.remove(user.id);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: Row(
              children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.blue.shade400, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 180, child: Text(user.email, style: TextStyle(color: Colors.grey.shade700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: getRoleColor(user.role).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: Text(user.role, style: TextStyle(color: getRoleColor(user.role), fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 12),
         SizedBox(
  width: 100,
  child: GestureDetector(
    onTap: () {
      setState(() {
        user.status =
            user.status == 'Active' ? 'Inactive' : 'Active';
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: user.status == 'Active'
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: user.status == 'Active'
                  ? Colors.green.shade500
                  : Colors.red.shade500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              user.status,
              style: TextStyle(
                color: user.status == 'Active'
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  ),
),

          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), color: Colors.blue.shade400, iconSize: 18, onPressed: () => _showEditUserDialog(context, user)),
                IconButton(icon: const Icon(Icons.delete), color: Colors.red.shade400, iconSize: 18, onPressed: () => _deleteUser(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBulkAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected action: $action')));
  }

  void _showAddUserDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add User Dialog')));
  }

  void _showEditUserDialog(BuildContext context, User user) {
  final nameCtrl = TextEditingController(text: user.name);
  final emailCtrl = TextEditingController(text: user.email);
  String role = user.role;
  String status = user.status;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          DropdownButtonFormField(
            value: role,
            items: ['Admin', 'Faculty', 'Student']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => role = v!,
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          DropdownButtonFormField(
            value: status,
            items: ['Active', 'Inactive']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => status = v!,
            decoration: const InputDecoration(labelText: 'Status'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () {
            setState(() {
              user.name = nameCtrl.text;
              user.email = emailCtrl.text;
              user.role = role;
              user.status = status;
            });
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}


  void _deleteUser(User user) {
    setState(() {
      allUsers.removeWhere((u) => u.id == user.id);
      filterUsers();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted User: ${user.name}')));
  }

 Future<void> fetchUsers() async {
  try {
    print('Fetching users from: $backendUrl/users');
    final response = await http.get(Uri.parse('$backendUrl/users'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      setState(() {
        allUsers = data.map((user) {
          return User(
            id: user['id']?.toString() ?? user['_id']?.toString() ?? '',
            name: user['name'] ?? 'Unknown',
            email: user['email'] ?? '',
            role: user['role'] ?? 'Student',
            status: user['status'] ?? 'Active',
          );
        }).toList();

        filterUsers();
        isLoading = false; // ✅ ALWAYS STOP LOADING
      });
    } else {
      setState(() => isLoading = false); // ✅
      debugPrint('API error: ${response.statusCode}');
    }
  } catch (e) {
    setState(() => isLoading = false); // ✅
    debugPrint('Fetch error: $e');
  }
}

}
