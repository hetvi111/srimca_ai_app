import 'package:flutter/material.dart';

/// ================= CONTENT ITEM MODEL =================
class ContentItem {
  String id;
  String title;
  String uploader;
  String status; // Pending / Approved / Outdated

  ContentItem({
    required this.id,
    required this.title,
    required this.uploader,
    required this.status,
  });
}

/// ================= CONTENT CONTROL PAGE =================
class ContentControlPage extends StatefulWidget {
  const ContentControlPage({super.key});

  @override
  State<ContentControlPage> createState() => _ContentControlPageState();
}

class _ContentControlPageState extends State<ContentControlPage> {
  List<ContentItem> contentList = [
    ContentItem(
        id: "1",
        title: "Flutter Basics Notes",
        uploader: "Faculty A",
        status: "Pending"),
    ContentItem(
        id: "2",
        title: "AI Knowledge: NLP",
        uploader: "Faculty B",
        status: "Approved"),
    ContentItem(
        id: "3",
        title: "Outdated ML Example",
        uploader: "Faculty C",
        status: "Outdated"),
  ];

  /// ================= APPROVE CONTENT =================
  void approveContent(ContentItem item) {
    setState(() {
      item.status = "Approved";
    });
  }

  /// ================= REMOVE CONTENT =================
  void removeContent(ContentItem item) {
    setState(() {
      contentList.removeWhere((c) => c.id == item.id);
    });
  }

  /// ================= MARK OUTDATED =================
  void markOutdated(ContentItem item) {
    setState(() {
      item.status = "Outdated";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Content & Knowledge Control",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: contentList.isEmpty
            ? const Center(
          child: Text(
            "No content available.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : ListView.builder(
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final item = contentList[index];

            /// Status color coding
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
                subtitle: Text("Uploader: ${item.uploader}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Status Text
                    Text(
                      item.status,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    /// Action Buttons Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Approve button only for Pending
                        if (item.status == "Pending")
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            ),
                            tooltip: "Approve",
                            onPressed: () => approveContent(item),
                          ),

                        // Mark as Outdated button for Pending or Approved
                        if (item.status != "Outdated")
                          IconButton(
                            icon: const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 20,
                            ),
                            tooltip: "Mark as Outdated",
                            onPressed: () => markOutdated(item),
                          ),

                        // Remove button always visible
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: "Remove",
                          onPressed: () => removeContent(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
