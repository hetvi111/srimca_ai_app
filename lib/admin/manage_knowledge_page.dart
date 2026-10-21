import 'package:flutter/material.dart';
import 'package:srimca_ai/api_service.dart';

class ManageKnowledgePage extends StatefulWidget {
  const ManageKnowledgePage({super.key});

  @override
  State<ManageKnowledgePage> createState() => _ManageKnowledgePageState();
}

class _ManageKnowledgePageState extends State<ManageKnowledgePage> {
  List<dynamic> materials = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      // Fetch materials from backend API
      final materialsList = await ApiService.getMaterials();
      if (mounted) {
        setState(() {
          materials = materialsList;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading materials: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Knowledge Base"),
        backgroundColor: const Color(0xFF1F4E8C),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : materials.isEmpty
              ? const Center(
                  child: Text(
                    "No materials uploaded yet",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(material['title'] ?? 'Untitled'),
                        subtitle: Text("${material['type'] ?? 'Material'} - ${material['subject'] ?? 'Unknown'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delete feature coming soon')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
