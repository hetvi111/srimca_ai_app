import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:srimca_ai/api_service.dart';

class VisitorPassApprovalView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const VisitorPassApprovalView({super.key, this.onBackToDashboard});

  @override
  State<VisitorPassApprovalView> createState() => _VisitorPassApprovalViewState();
}

class _VisitorPassApprovalViewState extends State<VisitorPassApprovalView> {
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color bgLight = Color(0xFFF8F9FA);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _passes = [];

  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, pending, approved, rejected
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.getVisitorPasses(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _passes = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load visitor pass applications: $e';
        _isLoading = false;
      });
    }
  }

  int get _countAll => _passes.length;
  int get _countPending => _passes.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'pending').length;
  int get _countApproved => _passes.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'approved').length;
  int get _countRejected => _passes.where((p) => (p['status'] ?? '').toString().toLowerCase() == 'rejected').length;

  List<Map<String, dynamic>> get _filteredPasses {
    return _passes.where((p) {
      if (_selectedStatus != 'all') {
        final st = (p['status'] ?? '').toString().toLowerCase();
        if (st != _selectedStatus) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        final phone = (p['phone'] ?? '').toString().toLowerCase();
        final purpose = (p['purpose'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !email.contains(q) && !phone.contains(q) && !purpose.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: RefreshIndicator(
        onRefresh: _fetchPasses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMetricCards(),
              const SizedBox(height: 20),
              _buildSearchAndFilterBar(),
              const SizedBox(height: 20),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBackToDashboard != null) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryNavy),
            onPressed: widget.onBackToDashboard,
            tooltip: 'Back to Dashboard',
          ),
          const SizedBox(width: 8),
        ],
        const Icon(Icons.badge_outlined, color: primaryNavy, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visitor Pass Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Review visitor applications, approve or reject requests, and issue secure QR passes',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _fetchPasses,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryNavy,
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatChip('Total Requests', '$_countAll', Icons.people_outline, Colors.blueGrey, 'all'),
            _buildStatChip('Pending Review', '$_countPending', Icons.hourglass_top_outlined, Colors.orange, 'pending'),
            _buildStatChip('Approved Passes', '$_countApproved', Icons.check_circle_outline, Colors.green, 'approved'),
            _buildStatChip('Rejected', '$_countRejected', Icons.cancel_outlined, Colors.red, 'rejected'),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String title, String count, IconData icon, Color color, String filterKey) {
    final isSelected = _selectedStatus == filterKey;
    return InkWell(
      onTap: () {
        setState(() => _selectedStatus = filterKey);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : Colors.grey[700],
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : primaryNavy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by visitor name, email, phone, purpose...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                icon: const Icon(Icons.arrow_drop_down, color: primaryNavy),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Only')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved Only')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected Only')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchPasses,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    final displayList = _filteredPasses;

    if (displayList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No visitor pass applications found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedStatus != 'all' || _searchQuery.isNotEmpty
                  ? 'Try clearing the search query or changing the status filter.'
                  : 'New visitor registration requests will appear here for administrative approval.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pass = displayList[index];
        return _buildPassCard(pass);
      },
    );
  }

  Widget _buildPassCard(Map<String, dynamic> pass) {
    final status = (pass['status'] ?? 'pending').toString().toLowerCase();
    final name = pass['name'] ?? 'Visitor';
    final email = pass['email'] ?? '';
    final phone = pass['phone'] ?? '';
    final purpose = pass['purpose'] ?? 'General Campus Visit';
    final visitDate = pass['visit_date'] ?? 'N/A';
    final passId = pass['_id'] ?? '';
    final remarks = pass['approval_remarks'] ?? '';
    final createdAt = pass['created_at'] != null ? pass['created_at'].toString().split('T')[0] : '';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = const Color(0xFFC62828);
        statusBg = const Color(0xFFFFEBEE);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFFEF6C00);
        statusBg = const Color(0xFFFFF3E0);
        statusIcon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Purpose: $purpose',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (email.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_outlined, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        if (phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_outlined, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        if (visitDate.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Visit: $visitDate', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                      ],
                    ),
                    if (remarks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Remarks: $remarks',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt.isNotEmpty ? 'Applied: $createdAt' : 'ID: ${passId.length > 8 ? passId.substring(0, 8) : passId}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showDetailsDialog(pass),
                    icon: const Icon(Icons.info_outline, size: 15),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryNavy,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (status == 'pending') ...[
                    ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(pass),
                      icon: const Icon(Icons.check, size: 15),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(pass),
                      icon: const Icon(Icons.close, size: 15),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  if (status == 'approved') ...[
                    ElevatedButton.icon(
                      onPressed: () => _showQrPassDialog(pass),
                      icon: const Icon(Icons.qr_code_2, size: 16),
                      label: const Text('View QR Pass'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> pass) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.badge, color: primaryNavy),
              const SizedBox(width: 8),
              const Text('Visitor Pass Details', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Visitor Name', pass['name'] ?? 'Visitor'),
                  _detailRow('Status', (pass['status'] ?? 'pending').toString().toUpperCase()),
                  _detailRow('Contact Phone', pass['phone'] ?? 'N/A'),
                  _detailRow('Email Address', pass['email'] ?? 'N/A'),
                  _detailRow('Purpose of Visit', pass['purpose'] ?? 'General Campus Visit'),
                  _detailRow('Scheduled Date', pass['visit_date'] ?? 'N/A'),
                  _detailRow('Application ID', pass['_id'] ?? 'N/A'),
                  if (pass['approval_remarks'] != null && pass['approval_remarks'].toString().isNotEmpty)
                    _detailRow('Remarks', pass['approval_remarks']),
                  if (pass['rejection_reason'] != null && pass['rejection_reason'].toString().isNotEmpty)
                    _detailRow('Rejection Reason', pass['rejection_reason']),
                  if (pass['pass_token'] != null && pass['pass_token'].toString().isNotEmpty)
                    _detailRow('Security Pass Token', pass['pass_token']),
                  if (pass['created_at'] != null)
                    _detailRow('Created At', pass['created_at'].toString()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if ((pass['status'] ?? '').toString().toLowerCase() == 'approved')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showQrPassDialog(pass);
                },
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text('Show QR Pass'),
                style: ElevatedButton.styleFrom(backgroundColor: accentBlue, foregroundColor: Colors.white),
              ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: primaryNavy),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> pass) {
    final remarksController = TextEditingController();
    String validUntilDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  const Text('Approve Visitor Pass', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approve visitor application for ${pass['name'] ?? 'Visitor'}?',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Approval Remarks / Gate Instructions (Optional)',
                        hintText: 'e.g., Allowed entry via Main Gate 1 for Seminar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Pass Valid Until: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                validUntilDate = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(validUntilDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security, size: 16, color: accentBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A cryptographically signed verification QR pass will be generated without exposing raw personal contact info.',
                              style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _executeApprove(pass['_id'], remarksController.text.trim(), validUntilDate, pass['name'] ?? 'Visitor');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Approval'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeApprove(String id, String remarks, String validUntil, String visitorName) async {
    setState(() => _isLoading = true);
    final res = await ApiService.approveVisitorPass(id, remarks: remarks, validUntil: validUntil);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Visitor pass approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetchPasses();

      // Show generated QR pass modal directly
      final verificationUrl = res['verification_url'] ?? (res['pass_token'] != null ? 'https://srimcaai.web.app/#/visitor-pass?token=${res['pass_token']}' : '');
      if (mounted && verificationUrl.isNotEmpty) {
        _showQrPassModal(
          visitorName: visitorName,
          verificationUrl: verificationUrl,
          passToken: res['pass_token'] ?? '',
          validUntil: validUntil,
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Approval failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(Map<String, dynamic> pass) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Reject Visitor Pass', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject the pass request for ${pass['name'] ?? 'Visitor'}?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection (Optional)',
                    hintText: 'e.g., Campus closed for holidays / Missing sponsor info',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _executeReject(pass['_id'], reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeReject(String id, String reason) async {
    setState(() => _isLoading = true);
    final res = await ApiService.rejectVisitorPass(id, reason: reason);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Visitor pass rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await _fetchPasses();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Rejection failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showQrPassDialog(Map<String, dynamic> pass) {
    final token = pass['pass_token'] ?? pass['_id'] ?? '';
    final verificationUrl = 'https://srimcaai.web.app/#/visitor-pass?token=$token';
    _showQrPassModal(
      visitorName: pass['name'] ?? 'Visitor',
      verificationUrl: verificationUrl,
      passToken: token,
      validUntil: pass['valid_until'] ?? 'End of Day',
    );
  }

  void _showQrPassModal({
    required String visitorName,
    required String verificationUrl,
    required String passToken,
    required String validUntil,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Official Visitor Pass',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                    ],
                  ),
                  child: QrImageView(
                    data: verificationUrl,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  visitorName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Text(
                    'AUTHORIZED VISITOR - VALID UNTIL $validUntil',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Token: ${passToken.length > 16 ? passToken.substring(0, 16) : passToken}...',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Show this QR at the campus security gate for verification. No private visitor details are stored inside the raw QR text.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: verificationUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification URL copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy URL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
