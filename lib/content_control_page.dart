import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// For Android Emulator: use 'http://10.0.2.2:5000'
// For Real Phone: use your computer's local IP (run 'ipconfig' on Windows)
const String baseUrl = 'http://10.27.15.181:5000';
 // Change to your IP for real phone

// Upload Model
class FacultyUpload {
  final String id;
  final String name;
  final String uploadedTime;
  final String status;
  final String avatar;

  FacultyUpload({
    required this.id,
    required this.name,
    required this.uploadedTime,
    required this.status,
    required this.avatar,
  });

  factory FacultyUpload.fromJson(Map<String, dynamic> json) {
    return FacultyUpload(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      uploadedTime: json['uploaded_time'] ?? json['created_at'] ?? 'Unknown',
      status: json['status'] ?? 'Pending',
      avatar: _getAvatar(json['name'] ?? 'U'),
    );
  }

  static String _getAvatar(String name) {
    if (name.isEmpty) return '👤';
    final firstChar = name[0].toUpperCase();
    if ('AEIOU'.contains(firstChar)) return '👩';
    return '👨';
  }
}

class ContentControlPage extends StatefulWidget {
  const ContentControlPage({super.key});

  @override
  State<ContentControlPage> createState() => _ContentControlPageState();
}

class _ContentControlPageState extends State<ContentControlPage> {
  int currentPage = 1;
  String searchQuery = '';
  String selectedFilter = 'All';
  Set<String> selectedUploads = {};
  bool isLoading = true;
  String? error;

  List<FacultyUpload> allUploads = [];
  late List<FacultyUpload> filteredUploads;
  final int itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    filteredUploads = [];
    fetchUploads();
  }

  Future<void> fetchUploads() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/uploads'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allUploads = data.map((json) => FacultyUpload.fromJson(json)).toList();
          filteredUploads = allUploads;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load uploads: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
        filteredUploads = allUploads;
      });
    }
  }

  Future<void> approveUpload(String id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/uploads/approve/$id'));
      if (response.statusCode == 200) {
        setState(() {
          allUploads = allUploads.map((upload) {
            if (upload.id == id) {
              return FacultyUpload(
                id: upload.id,
                name: upload.name,
                uploadedTime: upload.uploadedTime,
                status: 'Approved',
                avatar: upload.avatar,
              );
            }
            return upload;
          }).toList();
          filterUploads();
        });
      }
    } catch (e) {
      // Fallback: update locally
      setState(() {
        allUploads = allUploads.map((upload) {
          if (upload.id == id) {
            return FacultyUpload(
              id: upload.id,
              name: upload.name,
              uploadedTime: upload.uploadedTime,
              status: 'Approved',
              avatar: upload.avatar,
            );
          }
          return upload;
        }).toList();
        filterUploads();
      });
    }
  }

  Future<void> rejectUpload(String id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/uploads/reject/$id'));
      if (response.statusCode == 200) {
        setState(() {
          allUploads = allUploads.map((upload) {
            if (upload.id == id) {
              return FacultyUpload(
                id: upload.id,
                name: upload.name,
                uploadedTime: upload.uploadedTime,
                status: 'Rejected',
                avatar: upload.avatar,
              );
            }
            return upload;
          }).toList();
          filterUploads();
        });
      }
    } catch (e) {
      // Fallback: update locally
      setState(() {
        allUploads = allUploads.map((upload) {
          if (upload.id == id) {
            return FacultyUpload(
              id: upload.id,
              name: upload.name,
              uploadedTime: upload.uploadedTime,
              status: 'Rejected',
              avatar: upload.avatar,
            );
          }
          return upload;
        }).toList();
        filterUploads();
      });
    }
  }

  Future<void> approveAllUploads() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/uploads/approve-all'));
      if (response.statusCode == 200) {
        setState(() {
          allUploads = allUploads.map((upload) {
            return FacultyUpload(
              id: upload.id,
              name: upload.name,
              uploadedTime: upload.uploadedTime,
              status: 'Approved',
              avatar: upload.avatar,
            );
          }).toList();
          filterUploads();
        });
      }
    } catch (e) {
      // Fallback: update locally
      setState(() {
        allUploads = allUploads.map((upload) {
          return FacultyUpload(
            id: upload.id,
            name: upload.name,
            uploadedTime: upload.uploadedTime,
            status: 'Approved',
            avatar: upload.avatar,
          );
        }).toList();
        filterUploads();
      });
    }
  }

  void filterUploads() {
    setState(() {
      filteredUploads = allUploads.where((upload) {
        final matchesSearch = upload.name.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesFilter = selectedFilter == 'All' || upload.status == selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
      currentPage = 1;
    });
  }

  int getTotalPages() {
    if (filteredUploads.isEmpty) return 1;
    return (filteredUploads.length / itemsPerPage).ceil();
  }

  List<FacultyUpload> getPaginatedUploads() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= filteredUploads.length) return [];
    final endIndex = startIndex + itemsPerPage;
    return filteredUploads.sublist(
      startIndex,
      endIndex > filteredUploads.length ? filteredUploads.length : endIndex,
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(error ?? 'Loading uploads...', style: const TextStyle(color: Colors.grey)),
          if (error != null)
            ElevatedButton(
              onPressed: fetchUploads,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white,
                ),
                title: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF1E40AF), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SRIMCA AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: fetchUploads,
                    color: Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No notifications')),
                      );
                    },
                    color: Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle),
                    onPressed: () {},
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading && allUploads.isEmpty
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Content & Knowledge Control',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review and manage uploads and AI data in the system',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Tab Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Approve Faculty Uploads', true),
                    const SizedBox(width: 12),
                    _buildTabButton('Manage AI Knowledge Base', false),
                    const SizedBox(width: 12),
                    _buildTabButton('Remove Outdated Data', false),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pending Uploads Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: Colors.blue.shade400, shape: BoxShape.circle),
                      child: const Icon(Icons.people, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending Faculty Uploads', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          Text('${filteredUploads.where((u) => u.status == 'Pending').length} Pending content approvals', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Search and Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        filterUploads();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search uploads...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A), fontSize: 12)),
                        DropdownButton<String>(
                          value: selectedFilter,
                          underline: const SizedBox(),
                          items: ['All', 'Pending', 'Approved', 'Rejected'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedFilter = value ?? 'All');
                            filterUploads();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Uploads Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 200, child: Text('Faculty', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13))),
                            const SizedBox(width: 20),
                            SizedBox(width: 150, child: Text('Uploaded', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13))),
                            const SizedBox(width: 20),
                            SizedBox(width: 100, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13))),
                            const SizedBox(width: 20),
                            SizedBox(width: 180, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13))),
                          ],
                        ),
                      ),
                      // Table Rows
                      ...getPaginatedUploads().map((upload) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 200,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                                      child: Center(child: Text(upload.avatar, style: const TextStyle(fontSize: 20))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(upload.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(width: 150, child: Text(upload.uploadedTime, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 100,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: upload.status == 'Approved' ? Colors.green.shade100 : 
                                           upload.status == 'Rejected' ? Colors.red.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    upload.status,
                                    style: TextStyle(
                                      color: upload.status == 'Approved' ? Colors.green.shade700 : 
                                             upload.status == 'Rejected' ? Colors.red.shade700 : Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (upload.status == 'Pending') ...[
                                      ElevatedButton.icon(
                                        onPressed: () => approveUpload(upload.id),
                                        icon: const Icon(Icons.check, size: 14),
                                        label: const Text('Approve', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => rejectUpload(upload.id),
                                        icon: const Icon(Icons.delete, size: 14),
                                        label: const Text('', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                      ),
                                    ] else if (upload.status == 'Approved') ...[
                                      Text('✓ Approved', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                                    ] else ...[
                                      Text('✗ Rejected', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pagination and Approve All
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                      ),
                      ...List.generate(getTotalPages(), (index) {
                        final pageNumber = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => currentPage = pageNumber),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentPage == pageNumber ? const Color(0xFF3B82F6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pageNumber.toString(),
                              style: TextStyle(
                                color: currentPage == pageNumber ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: currentPage < getTotalPages() ? () => setState(() => currentPage++) : null,
                      ),
                    ],
                  ),
                  Text(
                    'Showing ${(currentPage - 1) * itemsPerPage + 1} to ${(currentPage - 1) * itemsPerPage + getPaginatedUploads().length} of ${filteredUploads.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Approve All Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Approve All Uploads?'),
                        content: Text('Approve all ${filteredUploads.where((u) => u.status == 'Pending').length} pending uploads?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              approveAllUploads();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ All uploads approved!'), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('Approve All'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Approve All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.analytics, color: Color(0xFF1E3A8A), size: 32),
                          const SizedBox(height: 8),
                          Text('${allUploads.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          const Text('Total Uploads', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          Text('${allUploads.where((u) => u.status == 'Approved').length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text('Approved', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.pending, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text('${allUploads.where((u) => u.status == 'Pending').length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const Text('Pending', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF1E40AF) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF1E40AF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
