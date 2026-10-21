import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/push_notification_service.dart';

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
  String selectedFilter = 'all'; // 'all', 'exam', 'notice', 'event'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch role-based notifications from backend with type filter
      final notifs = await ApiService.getMyNotifications(
        type: selectedFilter == 'all' ? null : selectedFilter,
      );
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
        final demo = _getDemoNotifications();
        final filteredDemo = selectedFilter == 'all'
            ? demo
            : demo.where((n) => n['type'] == selectedFilter).toList();
        setState(() {
          notifications = filteredDemo;
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
        'type': 'notice',
        'title': 'Library Book Return Notice',
        'message': 'All students must return borrowed library books before the upcoming examination week.',
        'timestamp': '2024-02-18 09:15:00',
        'isRead': true,
      },
      {
        'id': '4',
        'type': 'exam',
        'title': 'Practical Exam Notice',
        'message': 'Practical examinations for all BCA & MCA courses will be held after theory exams.',
        'timestamp': '2024-02-16 11:45:00',
        'isRead': true,
      },
      {
        'id': '5',
        'type': 'event',
        'title': 'Annual Guest Lecture on AI',
        'message': 'Industry experts from TCS will conduct a workshop on Artificial Intelligence and Machine Learning.',
        'timestamp': '2024-02-15 13:20:00',
        'isRead': true,
      },
      {
        'id': '6',
        'type': 'notice',
        'title': 'Fee Payment Deadline Notice',
        'message': 'Last date for term fee submission is March 10, 2024.',
        'timestamp': '2024-02-14 10:00:00',
        'isRead': true,
      },
    ];
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Icons.quiz_outlined;
      case 'event':
        return Icons.event_available;
      case 'deadline':
        return Icons.access_time;
      case 'update':
        return Icons.update;
      case 'notice':
        return Icons.campaign_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Colors.redAccent;
      case 'event':
        return Colors.purple;
      case 'deadline':
        return Colors.orange;
      case 'update':
        return Colors.blue;
      case 'notice':
        return Colors.teal;
      case 'assignment':
        return Colors.deepPurple;
      default:
        return accentBlue;
    }
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'all', 'label': 'All Updates', 'icon': Icons.all_inbox},
      {'key': 'exam', 'label': 'Exams', 'icon': Icons.quiz},
      {'key': 'notice', 'label': 'Notices', 'icon': Icons.campaign},
      {'key': 'event', 'label': 'Events', 'icon': Icons.event},
    ];

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = selectedFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                avatar: Icon(
                  f['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : navyBlue,
                ),
                label: Text(
                  f['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : navyBlue,
                  ),
                ),
                selected: isSelected,
                selectedColor: navyBlue,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? navyBlue : Colors.grey[300]!,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedFilter = f['key'] as String;
                    });
                    _loadNotifications();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Count unread notifications
    final unreadCount = notifications.where((n) {
      final v = n['is_read'] ?? n['isRead'];
      return v == false;
    }).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Smart Notifications"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Send Test Notification',
            onPressed: () async {
              await PushNotificationService.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Test notification sent to device tray!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: isLoading
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
          ),
        ],
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
    final timestamp =
        (notification['created_at'] ?? notification['timestamp'] ?? '').toString();
    final isRead = (notification['is_read'] ?? notification['isRead'] ?? true);

    // Format timestamp
    String formattedDate = '';
    try {
      if (timestamp.isNotEmpty) {
        final dateTime = DateTime.parse(timestamp);
        formattedDate = _formatDate(dateTime);
      }
    } catch (_) {
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
          onTap: () async {
            final notifId = notification['_id']?.toString();
            if (!isRead && notifId != null && notifId.isNotEmpty) {
              await ApiService.markNotificationAsRead(notifId);
              await _loadNotifications();
            }

            if (mounted) {
              _showNotificationDetails(title, message, type);
            }
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
