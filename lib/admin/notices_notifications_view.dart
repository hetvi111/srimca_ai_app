import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:srimca_ai/api_service.dart';

const Color kAdminPrimary = Color(0xFF001F3F); // Navy Blue
const Color kAdminAccent = Color(0xFF1E88E5); // Vibrant Blue
const Color kAdminCardBg = Colors.white;
const Color kAdminTextDark = Color(0xFF0F172A);
const Color kAdminTextMuted = Color(0xFF64748B);

class NoticesNotificationsView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const NoticesNotificationsView({super.key, this.onBackToDashboard});

  @override
  State<NoticesNotificationsView> createState() => _NoticesNotificationsViewState();
}

class _NoticesNotificationsViewState extends State<NoticesNotificationsView> {
  List<Map<String, dynamic>> _notices = [];
  Map<String, dynamic>? _notificationStats;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  String _selectedTargetRole = 'all';

  @override
  void initState() {
    super.initState();
    _fetchNoticesAndStats();
  }

  Future<void> _fetchNoticesAndStats() async {
    setState(() => _isLoading = true);
    try {
      final noticesFuture = ApiService.getAdminNoticesList(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        status: _selectedStatus,
        targetRole: _selectedTargetRole,
      );
      final statsFuture = ApiService.getAdminNotificationStats();

      final results = await Future.wait([noticesFuture, statsFuture]);
      if (mounted) {
        setState(() {
          _notices = results[0] as List<Map<String, dynamic>>;
          _notificationStats = results[1] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),

          // Notification Delivery Stats Bar
          if (_notificationStats != null) ...[
            _buildStatsBar(),
            const SizedBox(height: 16),
          ],

          // Filter & Search Controls
          _buildFilterBar(),
          const SizedBox(height: 16),

          // Notices List / Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
                : _notices.isEmpty
                    ? _buildEmptyState()
                    : _buildNoticesTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notices & Announcements',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAdminTextDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Publish official campus notices with targeted audience delivery and notification tracking.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openAddEditNoticeDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Notice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kAdminAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final total = _notificationStats?['total_notifications'] ?? 0;
    final read = _notificationStats?['read_count'] ?? 0;
    final unread = _notificationStats?['unread_count'] ?? 0;
    final rate = _notificationStats?['delivery_rate'] ?? '0%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatPill('Total Dispatched', total.toString(), Icons.send_rounded, Colors.blue),
          _buildStatPill('Read by Users', read.toString(), Icons.mark_email_read_rounded, Colors.green),
          _buildStatPill('Unread', unread.toString(), Icons.mark_email_unread_rounded, Colors.orange),
          _buildStatPill('Engagement Rate', rate.toString(), Icons.insights_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: kAdminTextMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search notices by title or content...',
                prefixIcon: Icon(Icons.search, size: 20, color: kAdminTextMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _fetchNoticesAndStats();
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedStatus,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'published', child: Text('Published Only', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'draft', child: Text('Drafts Only', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
                _fetchNoticesAndStats();
              }
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Categories', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'notice', child: Text('Notice', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'event', child: Text('Event', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'exam', child: Text('Exam', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'announcement', child: Text('Announcement', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCategory = val);
                _fetchNoticesAndStats();
              }
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedTargetRole,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Target: All Users', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'student', child: Text('Target: Students', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'faculty', child: Text('Target: Faculty', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'visitor', child: Text('Target: Visitors', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedTargetRole = val);
                _fetchNoticesAndStats();
              }
            },
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
          Icon(Icons.campaign_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No notices found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAdminTextDark)),
          const SizedBox(height: 6),
          const Text('Create a notice or adjust your filters.', style: TextStyle(color: kAdminTextMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoticesTable() {
    return Container(
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _notices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final notice = _notices[i];
          final id = notice['_id']?.toString() ?? '';
          final title = notice['title']?.toString() ?? 'Notice';
          final content = notice['content']?.toString() ?? '';
          final category = (notice['category'] ?? 'notice').toString();
          final status = (notice['status'] ?? 'published').toString();
          final priority = (notice['priority'] ?? 'normal').toString();
          final target = (notice['target_role'] ?? 'all').toString();
          final created = notice['created_at']?.toString() ?? '';
          final expiry = notice['expiry_date']?.toString();

          final isPublished = status == 'published';

          Color priorityColor = Colors.grey;
          if (priority == 'urgent') {
            priorityColor = Colors.redAccent;
          } else if (priority == 'important') {
            priorityColor = Colors.orange;
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAdminTextDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPublished ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isPublished ? Colors.green.shade300 : Colors.grey.shade400),
                  ),
                  child: Text(
                    isPublished ? 'PUBLISHED' : 'DRAFT',
                    style: TextStyle(
                      color: isPublished ? Colors.green.shade800 : Colors.grey.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, color: kAdminTextDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Target Audience: $target • Published: ${_formatDate(created)} ${expiry != null && expiry.isNotEmpty ? "• Expires: $expiry" : ""}',
                  style: const TextStyle(fontSize: 11, color: kAdminTextMuted),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isPublished ? 'Unpublish to Draft' : 'Publish Immediately',
                  icon: Icon(
                    isPublished ? Icons.visibility_off_outlined : Icons.publish_rounded,
                    color: isPublished ? Colors.grey : Colors.green,
                  ),
                  onPressed: () async {
                    final newStatus = isPublished ? 'draft' : 'published';
                    final res = await ApiService.updateAdminNoticeItem(id, {'status': newStatus});
                    if (res['success'] == true) {
                      _fetchNoticesAndStats();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notice marked as $newStatus')),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Edit Notice',
                  icon: const Icon(Icons.edit_rounded, color: Colors.blueGrey),
                  onPressed: () => _openAddEditNoticeDialog(notice: notice),
                ),
                IconButton(
                  tooltip: 'Delete Notice',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteNotice(id, title),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAddEditNoticeDialog({Map<String, dynamic>? notice}) {
    final isEdit = notice != null;
    final titleCtrl = TextEditingController(text: notice?['title']?.toString() ?? '');
    final contentCtrl = TextEditingController(text: notice?['content']?.toString() ?? '');
    final expiryCtrl = TextEditingController(text: notice?['expiry_date']?.toString() ?? '');

    String category = notice?['category']?.toString() ?? 'notice';
    String targetRole = notice?['target_role']?.toString() ?? 'all';
    String priority = notice?['priority']?.toString() ?? 'normal';
    bool publishNow = notice?['status'] != 'draft';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Notice' : 'Create Notice & Announcement'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notice Title *',
                          hintText: 'e.g. End Semester Exam Timetable Released',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: category,
                              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'notice', child: Text('Notice')),
                                DropdownMenuItem(value: 'event', child: Text('Event')),
                                DropdownMenuItem(value: 'exam', child: Text('Exam Update')),
                                DropdownMenuItem(value: 'announcement', child: Text('Announcement')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => category = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: targetRole,
                              decoration: const InputDecoration(labelText: 'Target Audience', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Users')),
                                DropdownMenuItem(value: 'student', child: Text('Students Only')),
                                DropdownMenuItem(value: 'faculty', child: Text('Faculty Only')),
                                DropdownMenuItem(value: 'visitor', child: Text('Visitors Only')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => targetRole = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: priority,
                              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                                DropdownMenuItem(value: 'important', child: Text('Important')),
                                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => priority = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: expiryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Optional Expiry Date',
                                hintText: 'YYYY-MM-DD',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notice Content / Description *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Publish Immediately', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Active notices trigger notifications to target users', style: TextStyle(fontSize: 11)),
                        value: publishNow,
                        activeColor: Colors.green,
                        onChanged: (val) => setDialogState(() => publishNow = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final content = contentCtrl.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please provide Title and Content')),
                      );
                      return;
                    }

                    final payload = {
                      'title': title,
                      'content': content,
                      'category': category,
                      'target_role': targetRole,
                      'priority': priority,
                      'expiry_date': expiryCtrl.text.trim().isNotEmpty ? expiryCtrl.text.trim() : null,
                      'status': publishNow ? 'published' : 'draft',
                    };

                    Navigator.pop(ctx);
                    if (isEdit) {
                      final id = notice['_id']?.toString() ?? '';
                      final res = await ApiService.updateAdminNoticeItem(id, payload);
                      if (res['success'] == true) {
                        _fetchNoticesAndStats();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice updated')));
                      }
                    } else {
                      final res = await ApiService.createAdminNoticeItem(payload);
                      if (res['success'] == true) {
                        _fetchNoticesAndStats();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(publishNow ? 'Notice published successfully' : 'Notice saved as draft')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kAdminAccent, foregroundColor: Colors.white),
                  child: Text(isEdit ? 'Save Changes' : (publishNow ? 'Publish Notice' : 'Save Draft')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteNotice(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice'),
        content: Text('Are you sure you want to permanently delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteAdminNoticeItem(id);
              if (success) {
                _fetchNoticesAndStats();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
