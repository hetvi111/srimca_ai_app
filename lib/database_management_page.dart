import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= DATABASE MANAGEMENT PAGE =================
class DatabaseManagementPage extends StatefulWidget {
  const DatabaseManagementPage({super.key});

  @override
  State<DatabaseManagementPage> createState() => _DatabaseManagementPageState();
}

class _DatabaseManagementPageState extends State<DatabaseManagementPage> {
  bool isBackingUp = false;
  bool isRestoring = false;
  bool isLoading = true;
  String lastBackup = 'Never';
  Map<String, dynamic> dbInfo = {
    'database_name': 'srimca_ai',
    'version': '1.0.0',
    'size_mb': 0,
    'last_updated': '',
  };

  Map<String, dynamic> dbStats = {
    "users": 0,
    "notices": 0,
    "materials": 0,
    "queries": 0,
    "notifications": 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDatabaseOverview();
  }

  Future<void> _loadDatabaseOverview() async {
    final data = await ApiService.getDatabaseOverview();
    if (!mounted) return;
    setState(() {
      dbStats = (data['stats'] as Map<String, dynamic>? ?? dbStats);
      dbInfo = (data['info'] as Map<String, dynamic>? ?? dbInfo);
      lastBackup = (dbInfo['last_backup']?.toString().isNotEmpty ?? false)
          ? dbInfo['last_backup'].toString()
          : 'Never';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Database Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      "Last Backup: $lastBackup",
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
                    _buildInfoRow("Database Name", dbInfo["database_name"]?.toString() ?? 'srimca_ai'),
                    _buildInfoRow("Version", dbInfo["version"]?.toString() ?? '1.0.0'),
                    _buildInfoRow("Size", "${dbInfo["size_mb"]?.toString() ?? '0'} MB"),
                    _buildInfoRow("Last Updated", dbInfo["last_updated"]?.toString() ?? ''),
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
    final result = await ApiService.backupDatabase();
    if (mounted) {
      setState(() => isBackingUp = false);
      if (result['last_backup'] != null) {
        lastBackup = result['last_backup'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? "Database backup completed successfully!"),
        ),
      );
      _loadDatabaseOverview();
    }
  }

  Future<void> _performRestore() async {
    setState(() => isRestoring = true);
    final result = await ApiService.restoreDatabase();
    if (mounted) {
      setState(() => isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? "Database restored successfully!"),
        ),
      );
      _loadDatabaseOverview();
    }
  }

  Future<void> _optimizeDatabase() async {
    final success = await ApiService.optimizeDatabase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Database optimization completed!" : "Database optimization failed")),
    );
  }

  Future<void> _clearCache() async {
    final success = await ApiService.clearDatabaseCache();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Cache cleared successfully!" : "Cache clear failed")),
    );
  }
}
