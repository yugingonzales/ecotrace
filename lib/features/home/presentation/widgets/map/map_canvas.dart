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
/// The canvas memoizes its built map widget and only rebuilds it when an
/// input actually changes (`didUpdateWidget`). Opening the filter panel,
/// tapping the header, or animating the details sheet therefore no longer
/// recreates the [`TileLayer`]/[`MarkerLayer`] and their ~24 marker widget
/// trees on every `setState`.
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
  });

  final MapController mapController;

  final bool isSatellite;

  /// Active zone filter (`null` = all zones). Kept here so the canvas can
  /// re-filter markers with simple primitive (==) comparisons instead of
  /// reallocating lists on every chrome rebuild.
  final String? zoneFilter;

  /// Active status filter (`null` = all statuses).
  final TreeStatus? statusFilter;

  final String? selectedTreeId;

  final ValueChanged<MapTree> onTreeSelected;

  final VoidCallback onMapTap;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  static const _gpsPoint = LatLng(campusCenterLat, campusCenterLng);

  static final _campusBounds = LatLngBounds(
    const LatLng(campusMinLat, campusMinLng),
    const LatLng(campusMaxLat, campusMaxLng),
  );

  /// Campus bounds + ~two campus-widths of padding. The camera centre can
  /// roam just outside the site before the map stops following, and tiles are
  /// only ever fetched for this small area — panning into the open map is
  /// physically impossible, so no wasted tile traffic competes with the
  /// campus tiles you actually need.
  static final _roamBounds = LatLngBounds(
    const LatLng(campusMinLat - 0.005, campusMinLng - 0.008),
    const LatLng(campusMaxLat + 0.005, campusMaxLng + 0.008),
  );

  static const _tileUserAgent = 'com.ecotrace.ecotrace';

  /// Memoized map subtree. Rebuilt only when an input prop changes (see
  /// [didUpdateWidget]); when nothing changed, the identical widget instance
  /// is returned so `FlutterMap` and its layers skip rebuilding entirely.
  late Widget _map;

  /// One long-lived tile provider shared by every [`TileLayer`] build.
  ///
  /// A single `RetryClient`/connection pool stays alive for the canvas
  /// lifetime, and the built-in persistent cache is configured to treat
  /// tiles as fresh for a week so revisits and pans serve from disk instead
  /// of re-validating OSM/Esri tiles on every app launch.
  late final NetworkTileProvider _tileProvider = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      overrideFreshAge: const Duration(days: 7),
    ),
  );

  List<MapTree> get _visibleTrees => campusTrees
      .where(
        (tree) => widget.zoneFilter == null || tree.zone == widget.zoneFilter,
      )
      .where(
        (tree) =>
            widget.statusFilter == null || tree.status == widget.statusFilter,
      )
      .toList(growable: false);

  /// Padded bounding frame per zone — port of the admin `framingBounds`.
  static List<LatLng> _zoneFrame(CampusZone zone) {
    const pad = 0.0012;
    const lngPad = 0.0027;
    return [
      LatLng(zone.lat - pad, zone.lng - lngPad),
      LatLng(zone.lat - pad, zone.lng + lngPad),
      LatLng(zone.lat + pad, zone.lng + lngPad),
      LatLng(zone.lat + pad, zone.lng - lngPad),
    ];
  }

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
          // `containCenter` keeps the camera centre inside the padded campus
          // area: zooming out stays unrestricted (no stuck-zoom), while pans
          // cannot drift the site out of reach.
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
          PolygonLayer(
            polygons: [
              for (final zone in campusZones)
                Polygon<Object>(
                  points: _zoneFrame(zone),
                  color: zone.color.withValues(alpha: 0.06),
                  borderColor: zone.color.withValues(alpha: 0.55),
                  borderStrokeWidth: 1.5,
                ),
            ],
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
                  // Each marker is its own raster layer: during a camera pan
                  // the compositor reuses the cached marker paintings instead
                  // of re-drawing all 24 shadows + labels every frame.
                  child: RepaintBoundary(
                    child: TreeMarker(
                      code: tree.id,
                      color: tree.color,
                      selected: selectedTreeId == tree.id,
                      onTap: () => onTreeSelected(tree),
                    ),
                  ),
                ),
              Marker(
                key: const ValueKey('gps-position'),
                point: _gpsPoint,
                width: 20,
                height: 20,
                child: const GpsMarker(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
