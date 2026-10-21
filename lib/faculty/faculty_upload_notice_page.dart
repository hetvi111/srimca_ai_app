import 'package:flutter/material.dart';
import 'package:srimca_ai/static_data.dart';

class FacultyUploadNoticePage extends StatefulWidget {
  const FacultyUploadNoticePage({super.key});

  @override
  State<FacultyUploadNoticePage> createState() =>
      _FacultyUploadNoticePageState();
}

class _FacultyUploadNoticePageState extends State<FacultyUploadNoticePage> {

  final titleController = TextEditingController();
  final descController = TextEditingController();
  bool isUploading = false;

  String selectedSubject = "Java";

  List<String> subjects = [
    "Java",
    "Python",
    "DBMS",
    "AI",
  ];

  Future<void> uploadNotice() async {
    if (titleController.text.isEmpty || descController.text.isEmpty) return;

    setState(() => isUploading = true);

    try {
      // Mock upload notice (no backend)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => isUploading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notice Uploaded Successfully")),
        );
        titleController.clear();
        descController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Notice")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            DropdownButtonFormField(
              value: selectedSubject,
              items: subjects.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) {
                setState(() => selectedSubject = val.toString());
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isUploading ? null : uploadNotice,
              child: isUploading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Upload Notice"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }
}
