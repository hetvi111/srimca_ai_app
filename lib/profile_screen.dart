import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'security_profile.dart';
import 'help_page.dart';
import 'about_page.dart';
import 'package:srimca_ai/main.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class ProfileScreen extends StatefulWidget {
  final String role; // student or faculty
  final String userId;
  final String? enrollmentNumber;
  final String? course;
  final String? semester;

  ProfileScreen({
    super.key, 
    required this.role, 
    this.userId = '',
    this.enrollmentNumber,
    this.course,
    this.semester,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> profileData = {
    'name': 'User Name',
    'email': 'user@example.com',
  };
  bool notificationsEnabled = true;
  bool isDarkMode = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Use the passed userId from login
    final userId = widget.userId.isNotEmpty ? widget.userId : 'default_user_id';
    try {
      // Mock load profile (no backend)
      setState(() {
        profileData = {
          'name': 'Student Name',
          'email': 'student@srimca.com',
          'enrollmentNumber': widget.enrollmentNumber ?? 'ENR2024001',
          'course': widget.course ?? 'BCA',
          'semester': widget.semester ?? '5th Semester',
        };
        isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.role.toUpperCase()} Profile"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// ================= USER INFO CARD =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: accentBlue,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileData['name'] ?? 'User Name',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: navyBlue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileData['email'] ?? 'user@email.com',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ================= STUDENT DETAILS (Only for students) =================
                if (widget.role == "student")
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Student Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: navyBlue,
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        _buildDetailRow(Icons.badge, "Enrollment Number", profileData['enrollmentNumber'] ?? 'N/A'),
                        _buildDetailRow(Icons.school, "Course", profileData['course'] ?? 'N/A'),
                        _buildDetailRow(Icons.calendar_today, "Semester", profileData['semester'] ?? 'N/A'),
                        _buildDetailRow(Icons.email, "Email", profileData['email'] ?? 'N/A'),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                /// ================= ACCOUNT =================
                _settingsCard(
                  title: "Account",
                  children: [
                    _settingsTile(
                      icon: Icons.edit,
                      title: "Edit Profile",
                      onTap: () => _openPage(context, EditProfilePage(userId: widget.userId.isNotEmpty ? widget.userId : 'default_user_id')),
                    ),
                    _settingsTile(
                      icon: Icons.security,
                      title: "Security",
                      onTap: () => _openPage(context, const SecurityPages()),
                    ),
                  ],
                ),

                /// ================= ROLE BASED SECTION =================
                if (widget.role == "student")
                  _settingsCard(
                    title: "Student Options",
                    children: [
                      _settingsTile(
                        icon: Icons.book,
                        title: "My Assignments",
                        onTap: () {},
                      ),
                      _settingsTile(
                        icon: Icons.notifications_active,
                        title: "My Notices",
                        onTap: () {},
                      ),
                      _settingsTile(
                        icon: Icons.history,
                        title: "Chat History",
                        onTap: () {},
                      ),
                    ],
                  ),

                if (widget.role == "faculty")
                  _settingsCard(
                    title: "Faculty Options",
                    children: [
                      _settingsTile(
                        icon: Icons.upload_file,
                        title: "Upload Study Material",
                        onTap: () {},
                      ),
                      _settingsTile(
                        icon: Icons.analytics,
                        title: "AI Query Monitoring",
                        onTap: () {},
                      ),
                      _settingsTile(
                        icon: Icons.assignment,
                        title: "Manage Assignments",
                        onTap: () {},
                      ),
                    ],
                  ),

                /// ================= PREFERENCES =================
                _settingsCard(
                  title: "Preferences",
                  children: [
                    SwitchListTile(
                      value: notificationsEnabled,
                      title: const Text("Notifications"),
                      secondary: const Icon(Icons.notifications, color: accentBlue),
                      onChanged: (val) {
                        setState(() {
                          notificationsEnabled = val;
                        });
                      },
                    ),
                    SwitchListTile(
                      value: isDarkMode,
                      title: const Text("Dark Mode"),
                      secondary: const Icon(Icons.dark_mode, color: accentBlue),
                      onChanged: (val) {
                        setState(() {
                          isDarkMode = val;
                        });
                        MyApp.of(context)?.changeTheme(val);
                      },
                    ),
                    _settingsTile(
                      icon: Icons.help,
                      title: "Help & Support",
                      onTap: () => _openPage(context, const HelpPage()),
                    ),
                    _settingsTile(
                      icon: Icons.info,
                      title: "About App",
                      onTap: () => _openPage(context, const AboutPage()),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// ================= LOGOUT =================
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: navyBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= NAVIGATION =================
  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// ================= CARD STYLE =================
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: lightGrey,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        )
      ],
    );
  }

  /// ================= SETTINGS CARD =================
  Widget _settingsCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyBlue)),
          const Divider(color: Colors.grey),
          ...children,
        ],
      ),
    );
  }

  /// ================= SETTINGS TILE =================
  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: accentBlue),
      title: Text(title, style: const TextStyle(color: navyBlue)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
