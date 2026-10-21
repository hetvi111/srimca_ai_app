import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:srimca_ai/static_data.dart';

class UploadStudyMaterialPage extends StatefulWidget {
  const UploadStudyMaterialPage({super.key});

  @override
  State<UploadStudyMaterialPage> createState() =>
      _UploadStudyMaterialPageState();
}

class _UploadStudyMaterialPageState
    extends State<UploadStudyMaterialPage> {
  String? selectedFileName;
  final titleController = TextEditingController();
  final subjectController = TextEditingController();
  String selectedType = 'notes';
  bool isUploading = false;

  Future<void> pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> uploadMaterial() async {
    if (titleController.text.isEmpty || subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      // Mock upload material (no backend)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Upload Study Material"),
        backgroundColor: const Color(0xFF1F4E8C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Upload PDF File",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: "Subject",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField(
              value: selectedType,
              items: ['notes', 'syllabus', 'assignments']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value!),
              decoration: const InputDecoration(
                labelText: "Type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: pickPDF,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload_file,
                        size: 40,
                        color: Color(0xFF1F4E8C)),
                    SizedBox(height: 8),
                    Text("Tap to select PDF file"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (selectedFileName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(selectedFileName!),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F4E8C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isUploading ? null : uploadMaterial,
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text("Upload"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
