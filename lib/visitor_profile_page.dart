import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'visitor_qr_page.dart';

// Same Theme
const Color navyBlue = Color(0xFF001F3F);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class VisitorProfilePage extends StatefulWidget {
  final String userId;
  final String token;

  const VisitorProfilePage({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<VisitorProfilePage> createState() => _VisitorProfilePageState();
}

class _VisitorProfilePageState extends State<VisitorProfilePage> {
  Map<String, dynamic> profileData = {};
  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final profile = await ApiService.getProfile(widget.token, widget.userId);
      final logs = await ApiService.getHistory(widget.token, widget.userId);

      setState(() {
        profileData = profile ?? {};
        history = logs;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    await AuthService.clearAuth();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Visitor Profile"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                /// 👤 USER CARD
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: _card(),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: accentBlue,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        profileData['name'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                        ),
                      ),
                      Text(
                        profileData['email'] ?? '',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                /// 📋 VISITOR DETAILS
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: _card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Visitor Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                        ),
                      ),
                      Divider(),
                      _row(Icons.phone, "Phone", profileData['phone'] ?? 'N/A'),
                      _row(
                        Icons.work,
                        "Purpose",
                        profileData['purpose'] ?? 'N/A',
                      ),
                      _row(
                        Icons.verified,
                        "Status",
                        profileData['status'] ?? 'Active',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                /// 🔳 QR SECTION
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: _card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "QR Pass",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                        ),
                      ),
                      Divider(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VisitorQRPage(
                                token: widget.token,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.qr_code),
                        label: Text("Generate QR Pass"),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                /// 📜 HISTORY
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: _card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Visit History",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                        ),
                      ),
                      Divider(),
                      history.isEmpty
                          ? Text("No visits yet")
                          : Column(
                              children: history.map<Widget>((item) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.history,
                                    color: accentBlue,
                                  ),
                                  title: Text("Check-in: ${item['check_in']}"),
                                  subtitle: Text(item['status']),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                /// 🚪 LOGOUT
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: logout,
                  icon: Icon(Icons.logout),
                  label: Text("Logout"),
                ),
              ],
            ),
    );
  }

  /// 🔹 reusable row
  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: accentBlue),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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

  BoxDecoration _card() {
    return BoxDecoration(
      color: lightGrey,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    );
  }
}
