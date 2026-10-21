import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:srimca_ai/api_service.dart';

const Color kAdminPrimary = Color(0xFF001F3F); // Navy Blue
const Color kAdminAccent = Color(0xFF1E88E5); // Vibrant Blue
const Color kAdminCardBg = Colors.white;
const Color kAdminTextDark = Color(0xFF0F172A);
const Color kAdminTextMuted = Color(0xFF64748B);

class CampusNavigationManagementView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const CampusNavigationManagementView({super.key, this.onBackToDashboard});

  @override
  State<CampusNavigationManagementView> createState() => _CampusNavigationManagementViewState();
}

class _CampusNavigationManagementViewState extends State<CampusNavigationManagementView> {
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedVerified = 'all';

  final List<String> _categories = [
    'all',
    'academic',
    'administrative',
    'amenity',
    'sports',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final locs = await ApiService.getCampusLocations(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        verified: _selectedVerified,
      );
      if (mounted) {
        setState(() {
          _locations = locs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load campus locations: $e')),
        );
      }
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
          // Header & Add Button
          _buildHeader(),
          const SizedBox(height: 16),

          // Filters & Search Bar
          _buildFilterBar(),
          const SizedBox(height: 16),

          // Main Locations Table / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
                : _locations.isEmpty
                    ? _buildEmptyState()
                    : _buildLocationsTable(),
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
              'Campus Navigation Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAdminTextDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage campus landmarks, GPS coordinates, and destination aliases used by AI Navigation.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openAddEditDialog(),
          icon: const Icon(Icons.add_location_alt_rounded, size: 18),
          label: const Text('Add Location'),
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by location name, building, aliases...',
                prefixIcon: Icon(Icons.search, size: 20, color: kAdminTextMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _fetchLocations();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Category Filter
          DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.filter_list, size: 18, color: kAdminAccent),
            items: _categories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Text(
                  'Category: ${cat[0].toUpperCase()}${cat.substring(1)}',
                  style: const TextStyle(fontSize: 13, color: kAdminTextDark),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCategory = val);
                _fetchLocations();
              }
            },
          ),
          const SizedBox(width: 12),
          // Verified Status Filter
          DropdownButton<String>(
            value: _selectedVerified,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'true', child: Text('Verified GPS Only', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'false', child: Text('Unverified Only', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedVerified = val);
                _fetchLocations();
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
          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No campus locations found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kAdminTextDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search criteria or add a new campus location.',
            style: TextStyle(color: kAdminTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsTable() {
    return Container(
      decoration: BoxDecoration(
        color: kAdminCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _locations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final loc = _locations[index];
          final id = loc['_id']?.toString() ?? '';
          final name = loc['name']?.toString() ?? 'Unnamed';
          final category = (loc['category'] ?? 'academic').toString();
          final building = loc['building']?.toString() ?? '';
          final floor = loc['floor']?.toString() ?? '';
          final room = loc['room']?.toString() ?? '';
          final desc = loc['description']?.toString() ?? '';
          final lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
          final lon = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
          final isVerified = loc['coordinates_verified'] == true;
          final aliases = (loc['aliases'] as List<dynamic>? ?? []).join(', ');

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isVerified
                  ? const Color(0xFF00897B).withValues(alpha: 0.12)
                  : Colors.amber.shade100,
              child: Icon(
                Icons.location_on_rounded,
                color: isVerified ? const Color(0xFF00897B) : Colors.amber.shade900,
              ),
            ),
            title: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAdminTextDark),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVerified ? Colors.green.shade300 : Colors.amber.shade400,
                    ),
                  ),
                  child: Text(
                    isVerified ? 'Verified GPS' : 'Survey Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isVerified ? Colors.green.shade800 : Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (building.isNotEmpty || floor.isNotEmpty || room.isNotEmpty)
                  Text(
                    [building, floor, room].where((s) => s.isNotEmpty).join(' • '),
                    style: const TextStyle(fontSize: 12, color: kAdminTextDark, fontWeight: FontWeight.w500),
                  ),
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: kAdminTextMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  'GPS: ${lat != 0.0 && lon != 0.0 ? "$lat, $lon" : "Pending survey"} ${aliases.isNotEmpty ? "• Aliases: $aliases" : ""}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Preview on Map',
                  icon: const Icon(Icons.map_rounded, color: kAdminAccent),
                  onPressed: () => _showMapPreviewDialog(loc),
                ),
                IconButton(
                  tooltip: 'Edit Location',
                  icon: const Icon(Icons.edit_rounded, color: Colors.blueGrey),
                  onPressed: () => _openAddEditDialog(location: loc),
                ),
                IconButton(
                  tooltip: 'Delete Location',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteLocation(id, name),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMapPreviewDialog(Map<String, dynamic> loc) {
    final name = loc['name']?.toString() ?? 'Location';
    final lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
    final isVerified = loc['coordinates_verified'] == true;
    final hasValidCoords = lat != 0.0 && lon != 0.0 && isVerified;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_pin, color: kAdminAccent, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kAdminTextDark),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${loc['category']} • Coordinates: $lat, $lon',
                  style: const TextStyle(fontSize: 12, color: kAdminTextMuted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 320,
                    child: hasValidCoords
                        ? FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lon),
                              initialZoom: 17.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.srimca.ai',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lon),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Container(
                            color: Colors.amber.shade50,
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.gps_off_rounded, size: 48, color: Colors.amber.shade800),
                                  const SizedBox(height: 12),
                                  Text(
                                    'GPS Coordinates for $name are not yet field-verified.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'To maintain map accuracy without fabricated coordinates, please edit this location once surveyed.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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

  void _openAddEditDialog({Map<String, dynamic>? location}) {
    final isEdit = location != null;
    final nameCtrl = TextEditingController(text: location?['name']?.toString() ?? '');
    final buildingCtrl = TextEditingController(text: location?['building']?.toString() ?? '');
    final floorCtrl = TextEditingController(text: location?['floor']?.toString() ?? '');
    final roomCtrl = TextEditingController(text: location?['room']?.toString() ?? '');
    final descCtrl = TextEditingController(text: location?['description']?.toString() ?? '');
    final latCtrl = TextEditingController(text: location != null ? (location['latitude']?.toString() ?? '0.0') : '');
    final lonCtrl = TextEditingController(text: location != null ? (location['longitude']?.toString() ?? '0.0') : '');
    final aliasesCtrl = TextEditingController(
      text: (location?['aliases'] as List<dynamic>? ?? []).join(', '),
    );

    String category = location?['category']?.toString() ?? 'academic';
    bool verified = location?['coordinates_verified'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Campus Location' : 'Add Campus Location'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location Name *',
                          hintText: 'e.g. Central Library',
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
                                DropdownMenuItem(value: 'academic', child: Text('Academic')),
                                DropdownMenuItem(value: 'administrative', child: Text('Administrative')),
                                DropdownMenuItem(value: 'amenity', child: Text('Amenity / Canteen')),
                                DropdownMenuItem(value: 'sports', child: Text('Sports')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => category = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: buildingCtrl,
                              decoration: const InputDecoration(labelText: 'Building', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: floorCtrl,
                              decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: roomCtrl,
                              decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: lonCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: aliasesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Aliases / Query Keywords (comma-separated)',
                          hintText: 'e.g. library, central library, reading room',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Coordinates Verified by Field Survey', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Only enable after GPS survey confirmation', style: TextStyle(fontSize: 11)),
                        value: verified,
                        activeColor: kAdminAccent,
                        onChanged: (val) => setDialogState(() => verified = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter location name')),
                      );
                      return;
                    }

                    final lat = double.tryParse(latCtrl.text.trim()) ?? 0.0;
                    final lon = double.tryParse(lonCtrl.text.trim()) ?? 0.0;

                    final payload = {
                      'name': name,
                      'category': category,
                      'building': buildingCtrl.text.trim(),
                      'floor': floorCtrl.text.trim(),
                      'room': roomCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'latitude': lat,
                      'longitude': lon,
                      'aliases': aliasesCtrl.text.split(',').map((s) => s.trim()).toList(),
                      'coordinates_verified': verified && lat != 0.0 && lon != 0.0,
                    };

                    Navigator.pop(ctx);
                    if (isEdit) {
                      final id = location['_id']?.toString() ?? '';
                      final res = await ApiService.updateCampusLocation(id, payload);
                      if (res['success'] == true) {
                        _fetchLocations();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location updated successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to update location')),
                        );
                      }
                    } else {
                      final res = await ApiService.createCampusLocation(payload);
                      if (res['success'] == true) {
                        _fetchLocations();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Campus location created successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to create location')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAdminAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Location'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteLocation(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Campus Location'),
        content: Text('Are you sure you want to delete "$name"? AI Navigation will no longer locate this landmark.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteCampusLocation(id);
              if (success) {
                _fetchLocations();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted location "$name"')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete location')),
                );
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
