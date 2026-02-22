import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/api_service.dart' show AuthService;
import 'package:srimca_ai/edit_profile_page.dart';
import 'package:srimca_ai/security_profile.dart';
import 'package:srimca_ai/help_page.dart';
import 'package:srimca_ai/about_page.dart';
import 'package:srimca_ai/main.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class StudentProfilePage extends StatefulWidget {
  final String userId;
  final String? enrollmentNumber;
  final String? course;
  final String? semester;
  
  const StudentProfilePage({
    super.key, 
    required this.userId,
    this.enrollmentNumber,
    this.course,
    this.semester,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic> profileData = {
    'name': 'Student Name',
    'email': 'student@srimca.com',
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
    try {
      // First try to get stored local user data
      final localUser = await AuthService.getUser();
      
      // Try to get profile from backend
      final backendProfile = await AuthService.getUserProfile();
      
      setState(() {
        if (backendProfile != null && backendProfile.isNotEmpty) {
          // Use backend profile data
          final profile = backendProfile['profile'] ?? {};
          profileData = {
            'name': backendProfile['name'] ?? localUser?['name'] ?? 'Student Name',
            'email': backendProfile['email'] ?? localUser?['email'] ?? 'student@srimca.com',
            'enrollmentNumber': profile['enrollment_number'] ?? widget.enrollmentNumber ?? 'N/A',
            'course': widget.course ?? 'BCA',
            'semester': profile['semester'] ?? widget.semester ?? 'N/A',
            'phone': profile['phone'] ?? localUser?['phone'] ?? localUser?['mobile'] ?? '',
          };
        } else if (localUser != null && localUser.isNotEmpty) {
          // Fall back to local user data
          profileData = {
            'name': localUser['name'] ?? 'Student Name',
            'email': localUser['email'] ?? 'student@srimca.com',
            'enrollmentNumber': widget.enrollmentNumber ?? localUser['enrollmentNumber'] ?? 'N/A',
            'course': widget.course ?? localUser['course'] ?? 'BCA',
            'semester': widget.semester ?? localUser['semester'] ?? 'N/A',
            'phone': localUser['phone'] ?? localUser['mobile'] ?? '',
          };
        } else {
          // Use widget parameters as fallback
          profileData = {
            'name': localUser?['name'] ?? 'Student Name',
            'email': localUser?['email'] ?? 'student@srimca.com',
            'enrollmentNumber': widget.enrollmentNumber ?? 'N/A',
            'course': widget.course ?? 'BCA',
            'semester': widget.semester ?? 'N/A',
            'phone': localUser?['phone'] ?? localUser?['mobile'] ?? '',
          };
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.clearAuth();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Student Profile"),
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
                        profileData['name'] ?? 'Student Name',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: navyBlue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileData['email'] ?? 'student@email.com',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ================= STUDENT DETAILS =================
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
                      _buildDetailRow(Icons.phone, "Phone", profileData['phone'] ?? 'N/A'),
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

                /// ================= STUDENT OPTIONS =================
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
                  onPressed: _logout,
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

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

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
