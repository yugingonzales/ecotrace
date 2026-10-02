import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/campus_data.dart';
import '../../models/map_tree.dart';
import 'gps_marker.dart';
import 'tree_marker.dart';

/// Map canvas: tiles, zone halos and tree/GPS markers, isolated from the
/// `MapScreen` chrome.
///
class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.mapController,
    required this.isSatellite,
    required this.zoneFilter,
    required this.statusFilter,
    required this.selectedTreeId,
    required this.onTreeSelected,
    required this.onMapTap,
    required this.gpsPoint,
    required this.heading,
    required this.isTracking,
    required this.routeSegments,
    this.trees,
  });

  final MapController mapController;

  final bool isSatellite;

  final String? zoneFilter;

  /// Active status filter (`null` = all statuses).
  final TreeStatus? statusFilter;

  final String? selectedTreeId;

  final ValueChanged<MapTree> onTreeSelected;

  final VoidCallback onMapTap;

  final LatLng gpsPoint;

  final double heading;

  final bool isTracking;

  final List<List<LatLng>> routeSegments;

  final List<MapTree>? trees;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  static final _campusBounds = LatLngBounds(
    const LatLng(campusMinLat, campusMinLng),
    const LatLng(campusMaxLat, campusMaxLng),
  );

  static final _roamBounds = LatLngBounds(
    const LatLng(campusMinLat - 0.005, campusMinLng - 0.008),
    const LatLng(campusMaxLat + 0.005, campusMaxLng + 0.008),
  );

  static const _tileUserAgent = 'com.ecotrace.ecotrace';

  late Widget _map;

  /// One long-lived tile provider shared by every [`TileLayer`] build.
  ///
  late final NetworkTileProvider _tileProvider = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      overrideFreshAge: const Duration(days: 7),
    ),
  );

  List<MapTree> get _visibleTrees => (widget.trees ?? campusTrees)
      .where(
        (tree) => widget.zoneFilter == null || tree.zone == widget.zoneFilter,
      )
      .where(
        (tree) =>
            widget.statusFilter == null || tree.status == widget.statusFilter,
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _map = _buildMap();
  }

  @override
  void didUpdateWidget(MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        widget.isSatellite != oldWidget.isSatellite ||
        widget.zoneFilter != oldWidget.zoneFilter ||
        widget.statusFilter != oldWidget.statusFilter ||
        widget.selectedTreeId != oldWidget.selectedTreeId ||
        !identical(widget.trees, oldWidget.trees) ||
        widget.gpsPoint != oldWidget.gpsPoint ||
        widget.heading != oldWidget.heading ||
        widget.isTracking != oldWidget.isTracking ||
        widget.routeSegments != oldWidget.routeSegments ||
        !identical(widget.onTreeSelected, oldWidget.onTreeSelected) ||
        !identical(widget.onMapTap, oldWidget.onMapTap);
    if (changed) _map = _buildMap();
  }

  @override
  void dispose() {
    _tileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _map;
  Widget _buildMap() {
    final visibleTrees = _visibleTrees;
    final selectedTreeId = widget.selectedTreeId;
    final onTreeSelected = widget.onTreeSelected;

    return RepaintBoundary(
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          // Pinned before layout so the constraint pre-flight assert holds and
          // the map starts on campus (never at lat/lng 0,0) until the fit runs.
          initialCenter: const LatLng(campusCenterLat, campusCenterLng),
          initialZoom: 16,
          initialCameraFit: CameraFit.bounds(
            bounds: _campusBounds,
            padding: const EdgeInsets.fromLTRB(10, 104, 10, 144),
            maxZoom: 17.5,
          ),
          minZoom: 14,
          maxZoom: 19,
          backgroundColor: const Color(0xFFE6EDE1),
          cameraConstraint: CameraConstraint.containCenter(bounds: _roamBounds),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: (_, _) => widget.onMapTap(),
        ),
        children: [
          TileLayer(
            urlTemplate: widget.isSatellite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: _tileUserAgent,
            tileProvider: _tileProvider,
            maxNativeZoom: 19,
            maxZoom: 19,
            // Never request tiles outside the campus roam area.
            tileBounds: _roamBounds,
            // Defaults `keepBuffer: 2` / `panBuffer: 1` are already the sweet
            // spot; only shorten the tile pop-in so fast pans look snappier.
            tileDisplay: const TileDisplay.fadeIn(
              duration: Duration(milliseconds: 80),
            ),
            evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          ),
          MarkerLayer(
            markers: [
              for (final tree in visibleTrees)
                Marker(
                  key: ValueKey('tree-${tree.id}'),
                  point: LatLng(tree.lat, tree.lng),
                  width: 80,
                  height: 84,
                  alignment: Marker.computePixelAlignment(
                    width: 80,
                    height: 84,
                    left: 40,
                    top: 42,
                  ),
                  child: TreeMarker(
                    code: tree.id,
                    color: tree.color,
                    selected: selectedTreeId == tree.id,
                    onTap: () => onTreeSelected(tree),
                  ),
                ),
              Marker(
                key: const ValueKey('gps-position'),
                point: widget.gpsPoint,
                width: 52,
                height: 52,
                child: GpsMarker(
                  heading: widget.heading,
                  animate: widget.isTracking,
                ),
              ),
            ],
          ),
          if (widget.routeSegments.isNotEmpty)
            PolylineLayer(
              key: const ValueKey('tree-route'),
              polylines: [
                for (final segment in widget.routeSegments)
                  Polyline(
                    points: segment,
                    color: const Color(0xFF2563EB),
                    strokeWidth: 4,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
