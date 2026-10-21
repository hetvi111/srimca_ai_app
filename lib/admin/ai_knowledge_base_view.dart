import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

const Color kAdminPrimary = Color(0xFF001F3F); // Navy Blue
const Color kAdminAccent = Color(0xFF1E88E5); // Vibrant Blue
const Color kAdminCardBg = Colors.white;
const Color kAdminTextDark = Color(0xFF0F172A);
const Color kAdminTextMuted = Color(0xFF64748B);

class AIKnowledgeBaseView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const AIKnowledgeBaseView({super.key, this.onBackToDashboard});

  @override
  State<AIKnowledgeBaseView> createState() => _AIKnowledgeBaseViewState();
}

class _AIKnowledgeBaseViewState extends State<AIKnowledgeBaseView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 state: Official Knowledge Entries
  List<Map<String, dynamic>> _entries = [];
  bool _isLoadingEntries = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';

  // Tab 2 state: Unresolved Queries
  List<Map<String, dynamic>> _unresolvedQueries = [];
  bool _isLoadingUnresolved = true;
  String _unresolvedStatusFilter = 'pending';

  final List<String> _categories = [
    'all',
    'departments',
    'courses',
    'faculty',
    'facilities',
    'rules',
    'faqs',
    'admissions',
    'general',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          _fetchEntries();
        } else {
          _fetchUnresolvedQueries();
        }
      }
    });
    _fetchEntries();
    _fetchUnresolvedQueries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEntries() async {
    setState(() => _isLoadingEntries = true);
    try {
      final list = await ApiService.getKnowledgeEntries(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        status: _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _entries = list;
          _isLoadingEntries = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEntries = false);
    }
  }

  Future<void> _fetchUnresolvedQueries() async {
    setState(() => _isLoadingUnresolved = true);
    try {
      final list = await ApiService.getUnresolvedQueries(
        status: _unresolvedStatusFilter,
      );
      if (mounted) {
        setState(() {
          _unresolvedQueries = list;
          _isLoadingUnresolved = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUnresolved = false);
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

          // Tabs Navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: kAdminAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: kAdminTextMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  text: 'Official Knowledge Base (${_entries.length})',
                ),
                Tab(
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  text: 'Unresolved User Questions (${_unresolvedQueries.length})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKnowledgeTab(),
                _buildUnresolvedTab(),
              ],
            ),
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
              'AI Knowledge Base Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAdminTextDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage official college facts, syllabi, policies, and resolve real student queries for the AI Chat.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openAddEditDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Official Knowledge'),
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

  // ---------------------------------------------------------------------------
  // TAB 1: Official Knowledge Base
  // ---------------------------------------------------------------------------
  Widget _buildKnowledgeTab() {
    return Column(
      children: [
        _buildKnowledgeFilterBar(),
        const SizedBox(height: 14),
        Expanded(
          child: _isLoadingEntries
              ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
              : _entries.isEmpty
                  ? _buildEmptyState('No knowledge entries found.')
                  : _buildEntriesList(),
        ),
      ],
    );
  }

  Widget _buildKnowledgeFilterBar() {
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
                hintText: 'Search by topic, keyword, or official answer text...',
                prefixIcon: Icon(Icons.search, size: 20, color: kAdminTextMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _fetchEntries();
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox.shrink(),
            items: _categories.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text('Category: ${c[0].toUpperCase()}${c.substring(1)}', style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCategory = val);
                _fetchEntries();
              }
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedStatus,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'reviewed', child: Text('Reviewed', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
                _fetchEntries();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    return Container(
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final entry = _entries[i];
          final id = entry['_id']?.toString() ?? '';
          final title = (entry['title'] ?? 'Official Fact').toString();
          final text = (entry['text'] ?? '').toString();
          final category = (entry['category'] ?? 'general').toString();
          final status = (entry['status'] ?? 'approved').toString();
          final tags = (entry['tags'] as List<dynamic>? ?? []).join(', ');

          Color statusColor = Colors.green;
          if (status == 'pending') {
            statusColor = Colors.orange;
          } else if (status == 'reviewed') {
            statusColor = Colors.blue;
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(fontSize: 13, color: kAdminTextDark),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Keywords / Aliases: $tags',
                    style: const TextStyle(fontSize: 11, color: kAdminTextMuted),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit Entry',
                  icon: const Icon(Icons.edit_rounded, color: Colors.blueGrey),
                  onPressed: () => _openAddEditDialog(entry: entry),
                ),
                IconButton(
                  tooltip: 'Delete Entry',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteEntry(id, title),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Unresolved Queries
  // ---------------------------------------------------------------------------
  Widget _buildUnresolvedTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kAdminCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Questions asked by students/visitors that had no verified answers in AI knowledge:',
                style: TextStyle(fontSize: 13, color: kAdminTextMuted),
              ),
              DropdownButton<String>(
                value: _unresolvedStatusFilter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending Review', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'all', child: Text('All Questions', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _unresolvedStatusFilter = val);
                    _fetchUnresolvedQueries();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _isLoadingUnresolved
              ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
              : _unresolvedQueries.isEmpty
                  ? _buildEmptyState('No unresolved questions in this status.')
                  : _buildUnresolvedList(),
        ),
      ],
    );
  }

  Widget _buildUnresolvedList() {
    return Container(
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _unresolvedQueries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final q = _unresolvedQueries[i];
          final qid = q['_id']?.toString() ?? '';
          final question = q['question']?.toString() ?? '';
          final role = q['user_role']?.toString() ?? 'student';
          final status = (q['status'] ?? 'pending').toString();
          final approvedAnswer = q['approved_answer']?.toString() ?? '';

          final isPending = status == 'pending';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '"$question"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kAdminTextDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isPending ? Colors.orange.shade300 : Colors.green.shade300),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isPending ? Colors.orange.shade900 : Colors.green.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Asked by $role',
                  style: const TextStyle(fontSize: 11, color: kAdminTextMuted),
                ),
              ],
            ),
            subtitle: approvedAnswer.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Approved Answer: $approvedAnswer',
                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  )
                : null,
            trailing: isPending
                ? ElevatedButton.icon(
                    onPressed: () => _openResolveQueryDialog(qid, question),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Approve Answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAdminAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                : const Icon(Icons.done_all_rounded, color: Colors.green),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: kAdminTextMuted, fontSize: 14)),
        ],
      ),
    );
  }

  void _openAddEditDialog({Map<String, dynamic>? entry}) {
    final isEdit = entry != null;
    final titleCtrl = TextEditingController(text: entry?['title']?.toString() ?? '');
    final textCtrl = TextEditingController(text: entry?['text']?.toString() ?? '');
    final tagsCtrl = TextEditingController(
      text: (entry?['tags'] as List<dynamic>? ?? []).join(', '),
    );
    String category = entry?['category']?.toString() ?? 'departments';
    String status = entry?['status']?.toString() ?? 'approved';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Knowledge Entry' : 'Add Official Knowledge Entry'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Topic / Question Title *',
                          hintText: 'e.g. MCA Eligibility & Duration',
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
                                DropdownMenuItem(value: 'departments', child: Text('Departments')),
                                DropdownMenuItem(value: 'courses', child: Text('Courses')),
                                DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                                DropdownMenuItem(value: 'facilities', child: Text('Facilities')),
                                DropdownMenuItem(value: 'rules', child: Text('Rules & Regulations')),
                                DropdownMenuItem(value: 'faqs', child: Text('FAQs')),
                                DropdownMenuItem(value: 'admissions', child: Text('Admissions')),
                                DropdownMenuItem(value: 'general', child: Text('General')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => category = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'approved', child: Text('Approved (Live)')),
                                DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Keywords / Search Tags (comma-separated)',
                          hintText: 'e.g. mca, eligibility, admission criteria, fees',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: textCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Official Answer Content *',
                          hintText: 'Accurate official information retrieved by AI chat...',
                          border: OutlineInputBorder(),
                        ),
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
                    final text = textCtrl.text.trim();
                    if (title.isEmpty || text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out Title and Content')),
                      );
                      return;
                    }

                    final payload = {
                      'title': title,
                      'text': text,
                      'category': category,
                      'status': status,
                      'tags': tagsCtrl.text.split(',').map((s) => s.trim()).toList(),
                    };

                    Navigator.pop(ctx);
                    if (isEdit) {
                      final id = entry['_id']?.toString() ?? '';
                      final res = await ApiService.updateKnowledgeEntry(id, payload);
                      if (res['success'] == true) {
                        _fetchEntries();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Knowledge entry updated')),
                        );
                      }
                    } else {
                      final res = await ApiService.createKnowledgeEntry(payload);
                      if (res['success'] == true) {
                        _fetchEntries();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Official knowledge entry added')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAdminAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openResolveQueryDialog(String queryId, String question) {
    final ansCtrl = TextEditingController();
    String category = 'faqs';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Approve Answer for User Question'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question: "$question"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'faqs', child: Text('FAQs')),
                        DropdownMenuItem(value: 'departments', child: Text('Departments')),
                        DropdownMenuItem(value: 'courses', child: Text('Courses')),
                        DropdownMenuItem(value: 'facilities', child: Text('Facilities')),
                        DropdownMenuItem(value: 'rules', child: Text('Rules')),
                        DropdownMenuItem(value: 'admissions', child: Text('Admissions')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ansCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Approved Official Answer *',
                        hintText: 'Enter the official answer for the AI Assistant to use...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final answer = ansCtrl.text.trim();
                    if (answer.isEmpty) return;

                    Navigator.pop(ctx);
                    final res = await ApiService.resolveUnresolvedQuery(
                      queryId: queryId,
                      approvedAnswer: answer,
                      category: category,
                      title: question,
                    );

                    if (res['success'] == true) {
                      _fetchUnresolvedQueries();
                      _fetchEntries();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Answer approved and added to official Knowledge Base')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kAdminAccent, foregroundColor: Colors.white),
                  child: const Text('Save & Resolve'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEntry(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Knowledge Entry'),
        content: Text('Are you sure you want to delete "$title"? AI Chat will no longer use this entry.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteKnowledgeEntry(id);
              if (success) {
                _fetchEntries();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
