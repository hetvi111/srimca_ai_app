import 'package:flutter/material.dart';
import 'upload_study_material_page.dart';
import 'manage_knowledge_page.dart';

class KnowledgePage extends StatelessWidget {
  const KnowledgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Knowledge"),
        backgroundColor: const Color(0xFF1F4E8C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            knowledgeCard(
              context,
              icon: Icons.upload_file,
              title: "Upload Study Material",
              subtitle: "Upload syllabus, notes & assignments",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UploadStudyMaterialPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            knowledgeCard(
              context,
              icon: Icons.storage,
              title: "Manage Knowledge Base",
              subtitle: "View, edit or delete uploaded materials",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageKnowledgePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget knowledgeCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF1F4E8C)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }
}
