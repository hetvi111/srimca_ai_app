import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= SECURITY & MAINTENANCE PAGE =================
class SecurityMaintenancePage extends StatefulWidget {
  const SecurityMaintenancePage({super.key});

  @override
  State<SecurityMaintenancePage> createState() =>
      _SecurityMaintenancePageState();
}

class _SecurityMaintenancePageState extends State<SecurityMaintenancePage> {
  // Dummy API keys
  List<String> apiKeys = [
    "12345-ABCDE",
    "67890-FGHIJ",
  ];

  // System settings
  bool maintenanceMode = false;
  bool enableLogging = true;

  /// ================= ADD API KEY =================
  void addApiKey() {
    setState(() {
      apiKeys.add("${DateTime.now().millisecondsSinceEpoch}-KEY");
    });
  }

  /// ================= REMOVE API KEY =================
  void removeApiKey(String key) {
    setState(() {
      apiKeys.remove(key);
    });
  }

  /// ================= BACKUP DATABASE =================
  void backupDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Database backup completed!")),
    );
  }

  /// ================= RESTORE DATABASE =================
  void restoreDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Database restored from backup!")),
    );
  }

  /// ================= OPEN SETTINGS PAGE =================
  void openSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Security & Maintenance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            /// ================= API Key Management =================
            const Text("API Key Management",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...apiKeys.map((key) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(key),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeApiKey(key),
                ),
              ),
            )),
            ElevatedButton.icon(
              onPressed: addApiKey,
              icon: const Icon(Icons.add),
              label: const Text("Add API Key"),
            ),
            const SizedBox(height: 24),

            /// ================= Database Backup & Restore =================
            const Text("Database Backup & Restore",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: backupDatabase,
                    icon: const Icon(Icons.backup),
                    label: const Text("Backup"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: restoreDatabase,
                    icon: const Icon(Icons.restore),
                    label: const Text("Restore"),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// ================= System Settings =================
            const Text("System Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("Maintenance Mode"),
              value: maintenanceMode,
              onChanged: (val) {
                setState(() {
                  maintenanceMode = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text("Enable Logging"),
              value: enableLogging,
              onChanged: (val) {
                setState(() {
                  enableLogging = val;
                });
              },
            ),
            const SizedBox(height: 16),

            /// ================= Open Settings Page Button =================
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF1E40AF)),
              title: const Text("Advanced Settings"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: openSettingsPage,
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ADVANCED SETTINGS PAGE =================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool emailNotifications = true;
  bool autoBackup = false;
  bool darkMode = false; // Dark mode toggle

  /// ================= LOGOUT FUNCTION =================
  void logout() async {
    // Clear auth data and navigate to login
    await AuthService.clearAuth();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Advanced Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// Email Notifications
            SwitchListTile(
              title: const Text("Email Notifications"),
              value: emailNotifications,
              onChanged: (val) {
                setState(() {
                  emailNotifications = val;
                });
              },
            ),

            /// Automatic Backups
            SwitchListTile(
              title: const Text("Automatic Backups"),
              value: autoBackup,
              onChanged: (val) {
                setState(() {
                  autoBackup = val;
                });
              },
            ),

            /// Dark Mode / Light Mode Toggle
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: darkMode,
              onChanged: (val) {
                setState(() {
                  darkMode = val;
                });
                // Apply theme change app-wide using a simple solution
                // For full app: use state management like Provider or Riverpod
                final brightness = darkMode ? Brightness.dark : Brightness.light;
                final theme = Theme.of(context).copyWith(brightness: brightness);
                // Rebuild app with new theme
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Theme(
                      data: theme,
                      child: const SettingsPage(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// Save Settings Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings saved successfully!")),
                );
              },
              child: const Text("Save Settings"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            /// Logout Button
            ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

