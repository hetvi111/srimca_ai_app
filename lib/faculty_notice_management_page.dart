import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class FacultyNoticeManagementPage extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  
  const FacultyNoticeManagementPage({
    super.key,
    required this.facultyId,
    required this.facultyName,
  });

  @override
  State<FacultyNoticeManagementPage> createState() => _FacultyNoticeManagementPageState();
}

class _FacultyNoticeManagementPageState extends State<FacultyNoticeManagementPage> {
  List<dynamic> notices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    try {
      final noticesList = await ApiService.getNotices();
      if (mounted) {
        setState(() {
          notices = noticesList;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notices: $e');
      if (mounted) {
        setState(() {
          notices = _getDemoNotices();
          isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getDemoNotices() {
    return [
      {
        'id': '1',
        'title': 'Mid-Term Exam Schedule',
        'content': 'Mid-term examinations will commence from March 1st, 2024.',
        'priority': 'high',
        'created_at': '2024-02-20',
        'author': widget.facultyName,
      },
      {
        'id': '2',
        'title': 'Assignment Submission Deadline',
        'content': 'All assignments must be submitted by February 25, 2024.',
        'priority': 'medium',
        'created_at': '2024-02-18',
        'author': widget.facultyName,
      },
      {
        'id': '3',
        'title': 'Guest Lecture Announcement',
        'content': 'Dr. Sarah Johnson will conduct a guest lecture on AI.',
        'priority': 'low',
        'created_at': '2024-02-15',
        'author': widget.facultyName,
      },
    ];
  }

  Future<void> _createNotice() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = 'normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Notice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: navyBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: accentBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: accentBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Low'),
                        selected: selectedPriority == 'low',
                        onSelected: (selected) {
                          setModalState(() => selectedPriority = 'low');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Normal'),
                        selected: selectedPriority == 'normal',
                        onSelected: (selected) {
                          setModalState(() => selectedPriority = 'normal');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('High'),
                        selected: selectedPriority == 'high',
                        onSelected: (selected) {
                          setModalState(() => selectedPriority = 'high');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                          try {
                            await ApiService.createNotice(
                              title: titleController.text,
                              content: contentController.text,
                              priority: selectedPriority,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadNotices();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Notice created successfully!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              _loadNotices();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Notice created (demo mode)')),
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        'Post Notice',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNotice(String noticeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteNotice(noticeId);
        if (mounted) {
          _loadNotices();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          // Demo mode - just remove from local list
          setState(() {
            notices = notices.where((n) => n['id'] != noticeId).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted (demo mode)')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notice Management"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNotice,
        backgroundColor: accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Notice", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notices.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      return _buildNoticeCard(notice);
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
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No Notices Posted", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("Tap + to create your first notice", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    final title = notice['title'] ?? '';
    final content = notice['content'] ?? '';
    final priority = notice['priority'] ?? 'normal';
    final date = notice['created_at'] ?? '';
    final author = notice['author'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPriorityColor(priority).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: _getPriorityColor(priority)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyBlue)),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteNotice(notice['id']?.toString() ?? '');
                    }
                  },
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(author, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return accentBlue;
    }
  }
}
