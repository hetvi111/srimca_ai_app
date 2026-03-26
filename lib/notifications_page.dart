import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= NOTIFICATIONS PAGE =================
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // Fetch all notifications for admin
      final notifs = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          notifications = notifs;
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
      {"title": "Exam Schedule Released", "message": "The final exam schedule has been uploaded.", "date": "2024-01-15", "type": "exam"},
      {"title": "New Event: Tech Fest", "message": "Annual tech fest registration is open.", "date": "2024-01-14", "type": "event"},
      {"title": "Assignment Deadline", "message": "Submit your assignments before deadline.", "date": "2024-01-13", "type": "deadline"},
      {"title": "Holiday Notice", "message": "College will remain closed on Republic Day.", "date": "2024-01-12", "type": "notice"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNotificationDialog(),
          ),
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
                    
                    final notifType = (notification["type"] ?? notification["notification_type"] ?? "notice")
                        .toString()
                        .toLowerCase();
                    final isRead = (notification["is_read"] ?? notification["isRead"] ?? true) as bool;

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
                      case "notice":
                        typeColor = Colors.green;
                        typeIcon = Icons.notifications;
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
                    
                    // Show target info
                    String targetInfo = "";
                    final targetRole = notification["target_role"] ?? "all";
                    if (targetRole == "all") {
                      targetInfo = "📢 All Users";
                    } else if (targetRole == "student") {
                      final courses = notification["target_courses"] ?? [];
                      final semesters = notification["target_semesters"] ?? [];
                      if (courses.isNotEmpty || semesters.isNotEmpty) {
                        targetInfo = "🎓 Students: ${courses.join(', ')} ${semesters.isNotEmpty ? '(${semesters.join(', ')})' : ''}";
                      } else {
                        targetInfo = "🎓 All Students";
                      }
                    } else if (targetRole == "faculty") {
                      targetInfo = "👨‍🏫 Faculty Only";
                    } else if (targetRole == "admin") {
                      targetInfo = "🔧 Admin Only";
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withValues(alpha: 0.2),
                          child: Icon(typeIcon, color: typeColor),
                        ),
                        title: Text(
                          notification["title"] ?? "Notification",
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          )
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification["message"] ?? ""),
                            const SizedBox(height: 4),
                            Text(
                              "$dateStr • $targetInfo",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])
                            ),
                            if (notification["sender_name"] != null)
                              Text(
                                "From: ${notification["sender_name"]}",
                                style: TextStyle(fontSize: 11, color: Colors.grey[500])
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Notification"),
                                content: const Text("Are you sure you want to delete this notification?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              // Delete notification (would need API endpoint)
                              setState(() {
                                notifications.removeAt(index);
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddNotificationDialog() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedType = "notice";
    String targetRole = "all";
    List<String> selectedCourses = [];
    List<String> selectedSemesters = [];
    bool isEvent = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Send Notification"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Message",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Is this an event?
                CheckboxListTile(
                  value: isEvent,
                  onChanged: (val) {
                    setDialogState(() {
                      isEvent = val ?? false;
                      if (isEvent) {
                        targetRole = "all";
                      }
                    });
                  },
                  title: const Text("This is an Event"),
                  subtitle: const Text("Events are visible to all users"),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 12),
                
                // Notification Type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: "Type",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "notice", child: Text("Notice")),
                    DropdownMenuItem(value: "event", child: Text("Event")),
                    DropdownMenuItem(value: "assignment", child: Text("Assignment")),
                    DropdownMenuItem(value: "upload", child: Text("Study Material")),
                    DropdownMenuItem(value: "system", child: Text("System")),
                  ],
                  onChanged: isEvent ? null : (val) {
                    setDialogState(() {
                      selectedType = val ?? "notice";
                    });
                  },
                ),
                
                if (!isEvent) ...[
                  const SizedBox(height: 12),
                  
                  // Target Role
                  DropdownButtonFormField<String>(
                    value: targetRole,
                    decoration: const InputDecoration(
                      labelText: "Send To",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("All Users")),
                      DropdownMenuItem(value: "student", child: Text("Students")),
                      DropdownMenuItem(value: "faculty", child: Text("Faculty")),
                      DropdownMenuItem(value: "admin", child: Text("Admin Only")),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        targetRole = val ?? "all";
                      });
                    },
                  ),
                  
                  // Course selection (for students)
                  if (targetRole == "student") ...[
                    const SizedBox(height: 12),
                    const Text("Select Courses:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: [
                        "BCA", "BBA", "B.Com", "M.Com"
                      ].map((course) => FilterChip(
                        label: Text(course),
                        selected: selectedCourses.contains(course),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedCourses.add(course);
                            } else {
                              selectedCourses.remove(course);
                            }
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    const Text("Select Semesters:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: [
                        "1st", "2nd", "3rd", "4th", "5th", "6th"
                      ].map((sem) => FilterChip(
                        label: Text(sem),
                        selected: selectedSemesters.contains(sem),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedSemesters.add(sem);
                            } else {
                              selectedSemesters.remove(sem);
                            }
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                // Send notification
                final success = await ApiService.createNotification(
                  title: titleCtrl.text,
                  message: messageCtrl.text,
                  type: isEvent ? "event" : selectedType,
                  targetRole: targetRole,
                  targetCourses: selectedCourses,
                  targetSemesters: selectedSemesters,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notification sent successfully!")),
                  );
                  _loadNotifications();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to send notification")),
                  );
                }
              },
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}
