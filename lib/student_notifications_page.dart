import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class StudentNotificationsPage extends StatefulWidget {
  final String userId;
  
  const StudentNotificationsPage({
    super.key,
    required this.userId,
  });

  @override
  State<StudentNotificationsPage> createState() => _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // Fetch notifications from backend
      final notifs = await ApiService.getUserNotifications(widget.userId);
      if (mounted) {
        setState(() {
          notifications = notifs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      // Show demo data when API fails
      if (mounted) {
        setState(() {
          notifications = _getDemoNotifications();
          isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getDemoNotifications() {
    return [
      {
        'id': '1',
        'type': 'exam',
        'title': 'Mid-Term Exam Schedule',
        'message': 'Mid-term examinations will commence from March 1st, 2024. Detailed schedule is available on the notice board.',
        'timestamp': '2024-02-20 10:00:00',
        'isRead': false,
      },
      {
        'id': '2',
        'type': 'event',
        'title': 'Tech Fest 2024',
        'message': 'Annual Tech Fest "INNOVATE 2024" will be held on March 15-17, 2024. Register now to participate!',
        'timestamp': '2024-02-19 14:30:00',
        'isRead': false,
      },
      {
        'id': '3',
        'type': 'deadline',
        'title': 'Assignment Deadline',
        'message': 'AI Assignment submission deadline extended to February 25, 2024. Submit through student portal.',
        'timestamp': '2024-02-18 09:15:00',
        'isRead': true,
      },
      {
        'id': '4',
        'type': 'update',
        'title': 'System Maintenance',
        'message': 'The student portal will be unavailable on February 22, 2024 (2:00 AM - 6:00 AM) for maintenance.',
        'timestamp': '2024-02-17 16:00:00',
        'isRead': true,
      },
      {
        'id': '5',
        'type': 'exam',
        'title': 'Practical Exam Notice',
        'message': 'Practical examinations for all courses will be held after theory exams. Lab in-charge will share the schedule.',
        'timestamp': '2024-02-16 11:45:00',
        'isRead': true,
      },
      {
        'id': '6',
        'type': 'event',
        'title': 'Guest Lecture',
        'message': 'Dr. Sarah Johnson from MIT will conduct a guest lecture on "Future of AI" on February 28, 2024 at 2:00 PM.',
        'timestamp': '2024-02-15 13:20:00',
        'isRead': true,
      },
    ];
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'exam':
        return Icons.quiz;
      case 'event':
        return Icons.event;
      case 'deadline':
        return Icons.access_time;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'exam':
        return Colors.red;
      case 'event':
        return Colors.purple;
      case 'deadline':
        return Colors.orange;
      case 'update':
        return Colors.blue;
      default:
        return accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count unread notifications
    final unreadCount = notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Notifications",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'update';
    final title = notification['title'] ?? '';
    final message = notification['message'] ?? '';
    final timestamp = notification['timestamp'] ?? '';
    final isRead = notification['isRead'] ?? true;

    // Format timestamp
    String formattedDate = '';
    try {
      if (timestamp.isNotEmpty) {
        final dateTime = DateTime.parse(timestamp);
        formattedDate = _formatDate(dateTime);
      }
    } catch (e) {
      formattedDate = timestamp;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? lightGrey : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isRead ? null : Border.all(
          color: _getNotificationColor(type).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Mark as read and show details
            _showNotificationDetails(title, message, type);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: accentBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: navyBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showNotificationDetails(String title, String message, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: _getNotificationColor(type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navyBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
