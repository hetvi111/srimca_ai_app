import 'package:flutter/material.dart';

/// ================= NOTIFICATIONS PAGE =================
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [
    {"title": "Exam Schedule Released", "message": "The final exam schedule has been uploaded.", "date": "2024-01-15", "type": "exam"},
    {"title": "New Event: Tech Fest", "message": "Annual tech fest registration is open.", "date": "2024-01-14", "type": "event"},
    {"title": "Assignment Deadline", "message": "Submit your assignments before deadline.", "date": "2024-01-13", "type": "deadline"},
    {"title": "Holiday Notice", "message": "College will remain closed on Republic Day.", "date": "2024-01-12", "type": "notice"},
  ];

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
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          Color typeColor;
          IconData typeIcon;
          switch (notification["type"]) {
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
            default:
              typeColor = Colors.green;
              typeIcon = Icons.info;
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: typeColor.withValues(alpha: 0.2),
                child: Icon(typeIcon, color: typeColor),
              ),
              title: Text(notification["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification["message"]),
                  const SizedBox(height: 4),
                  Text(notification["date"], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    notifications.removeAt(index);
                  });
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Notification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: messageCtrl,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "notice", child: Text("Notice")),
                DropdownMenuItem(value: "exam", child: Text("Exam")),
                DropdownMenuItem(value: "event", child: Text("Event")),
                DropdownMenuItem(value: "deadline", child: Text("Deadline")),
              ],
              onChanged: (value) => selectedType = value!,
              decoration: const InputDecoration(labelText: "Type"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && messageCtrl.text.isNotEmpty) {
                setState(() {
                  notifications.insert(0, {
                    "title": titleCtrl.text,
                    "message": messageCtrl.text,
                    "date": DateTime.now().toString().split(" ")[0],
                    "type": selectedType,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notification sent!")),
                );
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }
}
