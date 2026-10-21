import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:srimca_ai/visitor/visitor_theme.dart';

/// Interactive inline campus map widget rendered directly inside chat messages.
/// Displays OpenStreetMap tiles, location pin marker, zoom controls,
/// and OpenStreetMap attribution in compliance with OSM tile policy.
class CampusMapBubble extends StatefulWidget {
  final Map<String, dynamic> location;

  const CampusMapBubble({
    super.key,
    required this.location,
  });

  @override
  State<CampusMapBubble> createState() => _CampusMapBubbleState();
}

class _CampusMapBubbleState extends State<CampusMapBubble> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter(double lat, double lon) {
    _mapController.move(LatLng(lat, lon), 17.5);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.location['name'] as String? ?? 'Campus Location';
    final lat = (widget.location['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (widget.location['longitude'] as num?)?.toDouble() ?? 0.0;
    final building = widget.location['building'] as String? ?? '';
    final floor = widget.location['floor'] as String? ?? '';
    final room = widget.location['room'] as String? ?? '';
    final verified = widget.location['coordinates_verified'] == true;

    final hasValidCoords = lat != 0.0 && lon != 0.0 && verified;

    if (!hasValidCoords) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Coordinates for $name are currently pending official field survey. Interactive map pin is temporarily unavailable.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber.shade900,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final targetPoint = LatLng(lat, lon);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Location name & campus tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: chatIndigo.withValues(alpha: 0.06),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: chatIndigo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (building.isNotEmpty || floor.isNotEmpty || room.isNotEmpty)
                        Text(
                          [building, floor, room].where((s) => s.isNotEmpty).join(' • '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _recenter(lat, lon),
                  icon: const Icon(Icons.my_location, size: 14, color: chatIndigo),
                  label: const Text(
                    'Center',
                    style: TextStyle(fontSize: 11, color: chatIndigo),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map Area
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: targetPoint,
                    initialZoom: 17.5,
                    minZoom: 13.0,
                    maxZoom: 19.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.srimca.ai',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: targetPoint,
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            onTap: () => _recenter(lat, lon),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chatIndigo,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Map Zoom Controls (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    children: [
                      _buildMapButton(
                        icon: Icons.add,
                        tooltip: 'Zoom in',
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 4),
                      _buildMapButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom out',
                        onTap: _zoomOut,
                      ),
                    ],
                  ),
                ),

                // OpenStreetMap Attribution (Bottom Right)
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pinch or drag to explore Maliba Campus',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Text(
                  '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}
