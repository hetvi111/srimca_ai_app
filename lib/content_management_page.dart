import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

/// ================= CONTENT ITEM MODEL =================
class ContentItem {
  String id;
  String title;
  String uploader;
  String status;
  String type;

  ContentItem({
    required this.id,
    required this.title,
    required this.uploader,
    required this.status,
    required this.type,
  });

  factory ContentItem.fromMap(Map<String, dynamic> map, String itemType) {
    return ContentItem(
      id: map['_id'] ?? '',
      title: map['title'] ?? '',
      uploader: map['faculty_id'] ?? 'Unknown',
      status: map['is_active'] == false ? 'Outdated' : (map['status'] ?? 'Approved'),
      type: itemType,
    );
  }
}

/// ================= CONTENT MANAGEMENT PAGE =================
class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> with SingleTickerProviderStateMixin {
  List<ContentItem> contentList = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final materialsData = await ApiService.getMaterials();
      final noticesData = await ApiService.getNotices();
      
      setState(() {
        contentList = [
          ...materialsData.map((m) => ContentItem.fromMap(m, 'material')),
          ...noticesData.map((n) => ContentItem.fromMap(n, 'notice')),
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        contentList = [];
        isLoading = false;
      });
    }
  }

  Future<void> removeContent(ContentItem item) async {
    bool success;
    if (item.type == 'notice') {
      success = await ApiService.deleteNotice(item.id);
    } else {
      success = await ApiService.deleteMaterial(item.id);
    }
    
    if (success) {
      await _loadContent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content removed')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove content')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Content Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Materials"),
            Tab(text: "Notices"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaterialsList(),
          _buildNoticesList(),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    final materials = contentList.where((c) => c.type == 'material').toList();
    return _buildContentList(materials, "No materials uploaded yet.");
  }

  Widget _buildNoticesList() {
    final notices = contentList.where((c) => c.type == 'notice').toList();
    return _buildContentList(notices, "No notices uploaded yet.");
  }

  Widget _buildContentList(List<ContentItem> items, String emptyMessage) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (items.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        Color statusColor;
        switch (item.status) {
          case "Approved":
            statusColor = Colors.green;
            break;
          case "Pending":
            statusColor = Colors.orange;
            break;
          case "Outdated":
          default:
            statusColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(item.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Type: ${item.type}"),
                Text("Uploader: ${item.uploader}"),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  tooltip: "Remove",
                  onPressed: () => removeContent(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
