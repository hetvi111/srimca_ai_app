import 'package:flutter/material.dart';

/// ================= DATABASE MANAGEMENT PAGE =================
class DatabaseManagementPage extends StatefulWidget {
  const DatabaseManagementPage({super.key});

  @override
  State<DatabaseManagementPage> createState() => _DatabaseManagementPageState();
}

class _DatabaseManagementPageState extends State<DatabaseManagementPage> {
  bool isBackingUp = false;
  bool isRestoring = false;

  Map<String, dynamic> dbStats = {
    "users": 1250,
    "notices": 156,
    "materials": 423,
    "queries": 5678,
    "notifications": 89,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Database Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database Stats
            const Text("Database Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard("Users", dbStats["users"].toString(), Icons.people, Colors.blue),
                _buildStatCard("Notices", dbStats["notices"].toString(), Icons.campaign, Colors.green),
                _buildStatCard("Materials", dbStats["materials"].toString(), Icons.folder, Colors.orange),
                _buildStatCard("Queries", dbStats["queries"].toString(), Icons.chat, Colors.purple),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Backup & Restore
            const Text("Backup & Restore", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isBackingUp ? null : _performBackup,
                            icon: isBackingUp 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.backup),
                            label: Text(isBackingUp ? "Backing up..." : "Backup Database"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isRestoring ? null : _performRestore,
                            icon: isRestoring
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.restore),
                            label: Text(isRestoring ? "Restoring..." : "Restore Database"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Last Backup: 2024-01-15 10:30 AM",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Database Optimization
            const Text("Optimization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.speed, color: Colors.blue),
                title: const Text("Optimize Database"),
                subtitle: const Text("Clean up temporary data and optimize performance"),
                trailing: ElevatedButton(
                  onPressed: _optimizeDatabase,
                  child: const Text("Optimize"),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cleaning_services, color: Colors.red),
                title: const Text("Clear Cache"),
                subtitle: const Text("Remove temporary files and cache data"),
                trailing: ElevatedButton(
                  onPressed: _clearCache,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Clear"),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Database Info
            const Text("Database Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow("Database Name", "srimca_ai_db"),
                    _buildInfoRow("Version", "1.0.0"),
                    _buildInfoRow("Size", "125 MB"),
                    _buildInfoRow("Last Updated", "2024-01-15"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _performBackup() async {
    setState(() => isBackingUp = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => isBackingUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Database backup completed successfully!")),
      );
    }
  }

  Future<void> _performRestore() async {
    setState(() => isRestoring = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Database restored successfully!")),
      );
    }
  }

  void _optimizeDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Database optimization completed!")),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cache cleared successfully!")),
    );
  }
}
