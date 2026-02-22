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

class FacultyProfilePage extends StatefulWidget {
  final String userId;
  final String staffId;
  
  const FacultyProfilePage({
    super.key, 
    required this.userId,
    required this.staffId,
  });

  @override
  State<FacultyProfilePage> createState() => _FacultyProfilePageState();
}

class _FacultyProfilePageState extends State<FacultyProfilePage> {
  Map<String, dynamic> profileData = {
    'name': 'Faculty Name',
    'email': 'faculty@srimca.com',
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
            'name': backendProfile['name'] ?? localUser?['name'] ?? 'Faculty Name',
            'email': backendProfile['email'] ?? localUser?['email'] ?? 'faculty@srimca.com',
            'department': profile['department'] ?? localUser?['department'] ?? 'Computer Science',
            'designation': profile['designation'] ?? localUser?['designation'] ?? 'Professor',
            'phone': profile['phone'] ?? localUser?['phone'] ?? localUser?['mobile'] ?? '',
          };
        } else if (localUser != null && localUser.isNotEmpty) {
          // Fall back to local user data
          profileData = {
            'name': localUser['name'] ?? 'Faculty Name',
            'email': localUser['email'] ?? 'faculty@srimca.com',
            'department': localUser['department'] ?? 'Computer Science',
            'designation': localUser['designation'] ?? 'Professor',
            'phone': localUser['phone'] ?? localUser['mobile'] ?? '',
          };
        } else {
          // Use defaults
          profileData = {
            'name': localUser?['name'] ?? 'Faculty Name',
            'email': localUser?['email'] ?? 'faculty@srimca.com',
            'department': 'Computer Science',
            'designation': 'Professor',
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
        title: const Text("Faculty Profile"),
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
                        profileData['name'] ?? 'Faculty Name',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: navyBlue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileData['email'] ?? 'faculty@email.com',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ================= FACULTY DETAILS =================
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
                        "Faculty Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      _buildDetailRow(Icons.badge, "Designation", profileData['designation'] ?? 'N/A'),
                      _buildDetailRow(Icons.school, "Department", profileData['department'] ?? 'N/A'),
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

                /// ================= FACULTY OPTIONS =================
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
