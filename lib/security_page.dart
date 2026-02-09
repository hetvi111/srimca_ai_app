import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// For Android Emulator: http://10.0.2.2:5000
// For Real Phone: use your PC IP (ipconfig)
const String baseUrl = 'http://10.27.15.181:5000';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool maintenanceMode = false;
  bool emailNotifications = true;
  bool twoFactorAuth = true;

  bool isLoading = true;
  String? error;
  Map<String, dynamic> securityData = {};

  @override
  void initState() {
    super.initState();
    fetchSecurityData();
  }

  Future<void> fetchSecurityData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/security'));

      if (response.statusCode == 200) {
        setState(() {
          securityData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;

        // fallback (SAFE)
        securityData = {
          'threats': 12,
          'blocked_ips': 5,
          'logs': [
            "Login attempt from unknown IP",
            "Suspicious activity detected",
          ],
        };
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(error ?? 'Loading security data...',
              style: const TextStyle(color: Colors.grey)),
          if (error != null)
            ElevatedButton(
              onPressed: fetchSecurityData,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int threats = securityData['threats'] ?? 0;
    final int blockedIps = securityData['blocked_ips'] ?? 0;

    /// 🔥 FIXED PART (NO CRASH)
    final List<String> logs =
        (securityData['logs'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Security & Maintenance"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSecurityData,
          ),
        ],
      ),
      body: isLoading && securityData.isEmpty
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  _searchBox(),
                  const SizedBox(height: 20),
                  _securityStats(threats, blockedIps),
                  const SizedBox(height: 20),
                  _securityLogs(logs),
                  const SizedBox(height: 20),
                  _apiKeyManagement(),
                  const SizedBox(height: 20),
                  _backupRestore(),
                  const SizedBox(height: 20),
                  _systemSettings(),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      "© SRIMCA AI Dashboard · 2024",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  /* ---------------- HEADER ---------------- */

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 42),
          ),
          const SizedBox(width: 18),
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        "Manage Security Settings",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 6),
      Text(
        "Configure system security & backups",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white70),
      ),
    ],
  ),
),

        ],
      ),
    );
  }

  /* ---------------- SECURITY STATS ---------------- */

  Widget _securityStats(int threats, int blockedIps) {
    return Row(
      children: [
        Expanded(child: _statCard(threats, "Active Threats", Icons.warning, Colors.red)),
        const SizedBox(width: 15),
        Expanded(child: _statCard(blockedIps, "Blocked IPs", Icons.block, Colors.orange)),
      ],
    );
  }

  Widget _statCard(
  int value,
  String label,
  IconData icon,
  Color color,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 160;

      return _card(
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        label,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
      );
    },
  );
}


  /* ---------------- SECURITY LOGS ---------------- */

  Widget _securityLogs(List<String> logs) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Recent Security Logs",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          const Text("No security logs available",
              style: TextStyle(color: Colors.grey))
        else
          ...logs.map((log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text("• $log"),
              )),
      ]),
    );
  }

  /* ---------------- OTHER SECTIONS ---------------- */

  Widget _searchBox() => const TextField(
        decoration: InputDecoration(
          hintText: "Search settings...",
          prefixIcon: Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
      );

  Widget _apiKeyManagement() => _card(child: const Text("API Key Management"));
  Widget _backupRestore() => _card(child: const Text("Backup & Restore"));
  Widget _systemSettings() => _card(child: const Text("System Settings"));

  /* ---------------- REUSABLE ---------------- */

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: child,
    );
  }
}
