import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= FACULTY NOTIFICATIONS PAGE =================
class FacultyNotificationsPage extends StatefulWidget {
  const FacultyNotificationsPage({super.key});

  @override
  State<FacultyNotificationsPage> createState() => _FacultyNotificationsPageState();
}

class _FacultyNotificationsPageState extends State<FacultyNotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // Fetch role-based notifications for faculty
      final notifs = await ApiService.getMyNotifications();
      final adminNoticeOnly = notifs.where((n) {
        final senderRole = (n["sender_role"] ?? "").toString().toLowerCase();
        final notifType = (n["type"] ?? n["notification_type"] ?? "").toString().toLowerCase();
        return senderRole == "admin" && notifType == "notice";
      }).toList();

      if (mounted) {
        setState(() {
          notifications = adminNoticeOnly;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          notifications = _getDemoNotifications();
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDemoNotifications() {
    return [
      {"title": "New Assignment Submitted", "message": "A student has submitted a new assignment.", "date": "2024-01-15", "type": "assignment"},
      {"title": "Notice: Exam Duty", "message": "Please check your exam duty schedule.", "date": "2024-01-14", "type": "notice"},
      {"title": "Material Upload Request", "message": "New study material needs approval.", "date": "2024-01-13", "type": "upload"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("No notifications"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    Color typeColor;
                    IconData typeIcon;
                    
                    String notifType = notification["type"] ?? notification["notification_type"] ?? "notice";
                    switch (notifType) {
                      case "exam":
                        typeColor = Colors.red;
                        typeIcon = Icons.assignment;
                        break;
                      case "event":
                        typeColor = Colors.blue;
                        typeIcon = Icons.event;
                        break;
                      case "deadline":
                        typeColor = Colors.orange;
                        typeIcon = Icons.warning;
                        break;
                      case "assignment":
                        typeColor = Colors.purple;
                        typeIcon = Icons.assignment_turned_in;
                        break;
                      case "upload":
                      case "material":
                        typeColor = Colors.teal;
                        typeIcon = Icons.upload_file;
                        break;
                      default:
                        typeColor = Colors.green;
                        typeIcon = Icons.info;
                    }
                    
                    // Format date
                    String dateStr = "Unknown";
                    if (notification["created_at"] != null) {
                      try {
                        final date = notification["created_at"];
                        if (date is String) {
                          dateStr = date.substring(0, 10);
                        }
                      } catch (e) {}
                    } else if (notification["date"] != null) {
                      dateStr = notification["date"];
                    }
                    
                    final isRead = notification["is_read"] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isRead ? null : Color(0xFFE3F2FD),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withValues(alpha: 0.2),
                          child: Icon(typeIcon, color: typeColor),
                        ),
                        title: Text(
                          notification["title"] ?? "Notification",
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold
                          )
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification["message"] ?? ""),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])
                            ),
                          ],
                        ),
                        trailing: isRead 
                            ? null 
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () async {
                          // Mark as read
                          if (!isRead && notification["_id"] != null) {
                            await ApiService.markNotificationAsRead(notification["_id"]);
                            _loadNotifications();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
