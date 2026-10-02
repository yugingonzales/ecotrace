import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../../core/connectivity/app_connectivity_scope.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../field_verification/domain/tree_record.dart';
import '../../models/campus_data.dart';
import '../../models/map_tree.dart';
import '../../widgets/map/map_canvas.dart';
import '../../widgets/map/map_filter_panel.dart';
import '../../widgets/map/map_header.dart';
import '../../widgets/map/tree_details_card.dart';
import '../incident/incident_report_screen.dart';
import '../verification/start_verification_flow.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _gpsPoint = LatLng(campusCenterLat, campusCenterLng);

  final MapController _mapController = MapController();

  bool _satellite = false;
  bool _filtersOpen = false;
  bool _tracking = false;
  String? _zoneFilter;
  TreeStatus? _statusFilter;
  MapTree? _selectedTree;
  Position? _currentPosition;
  Set<String>? _nearbyTreeIds;
  List<List<LatLng>> _routeSegments = const [];
  bool _routing = false;
  StreamSubscription<Position>? _positionSubscription;

  final Map<String, TreeStatus> _verifiedStatuses = {};

  LatLng get _currentPoint => _currentPosition == null
      ? _gpsPoint
      : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

  List<MapTree> get _displayTrees {
    final trees = _trees;
    final ids = _nearbyTreeIds;
    if (ids == null) return trees;
    return trees.where((tree) => ids.contains(tree.id)).toList(growable: false);
  }

  List<MapTree> get _trees => _verifiedStatuses.isEmpty
      ? campusTrees
      : [
          for (final tree in campusTrees)
            _verifiedStatuses[tree.id] == null
                ? tree
                : tree.copyWith(status: _verifiedStatuses[tree.id]),
        ];

  int get _activeFilterCount =>
      (_zoneFilter == null ? 0 : 1) + (_statusFilter == null ? 0 : 1);

  // Stable callback instances (bound once) so MapCanvas.didUpdateWidget can
  // detect "nothing changed" and skip rebuilding the map subtree.
  late final ValueChanged<MapTree> _onTreeSelected = _selectTree;
  late final VoidCallback _onMapTap = _closeDetailsIfAny;

  void _selectTree(MapTree tree) {
    if (_selectedTree?.id == tree.id) return;
    setState(() => _selectedTree = tree);
  }

  void _closeDetails() => setState(() => _selectedTree = null);

  /// Map taps nudge the selected tree only when one is actually open — taps
  /// on empty map no longer trigger a full chrome + map rebuild.
  void _closeDetailsIfAny() {
    if (_selectedTree == null) return;
    setState(() => _selectedTree = null);
  }

  void _setZoneFilter(String? zone) {
    if (_zoneFilter == zone) return;
    setState(() => _zoneFilter = zone);
  }

  void _setStatusFilter(TreeStatus? status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
  }

  void _recenter() => _mapController.move(_currentPoint, 16);

  Future<void> _toggleTracking() async {
    if (_tracking) {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      if (mounted) setState(() => _tracking = false);
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      await _showLocationPrompt(
        'Location is off',
        'Enable device location so EcoTrace can show your position on the map.',
        Geolocator.openLocationSettings,
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await _showLocationPrompt(
        'Location permission needed',
        'Allow location access in system settings to use live tracking.',
        Geolocator.openAppSettings,
      );
      return;
    }
    if (permission == LocationPermission.denied) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _tracking = true;
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 3,
            ),
          ).listen((next) {
            if (!mounted) return;
            setState(() => _currentPosition = next);
          });
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read the current location.')),
      );
    }
  }

  Future<void> _showLocationPrompt(
    String title,
    String message,
    Future<bool> Function() openSettings,
  ) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (open == true) await openSettings();
  }

  Future<void> _findNearbyTrees() async {
    final controller = TextEditingController(text: '5');
    final count = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nearby trees'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'How many trees?',
            hintText: '1–20',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Find trees'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || count == null) return;
    final limit = count.clamp(1, 20).toInt();
    final ranked = [..._trees]
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    setState(() {
      _nearbyTreeIds = ranked.take(limit).map((tree) => tree.id).toSet();
      _selectedTree = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nearbyTreeIds!.length} nearby trees shown.')),
    );
  }

  double _distanceTo(MapTree tree) => Distance().as(
    LengthUnit.Meter,
    _currentPoint,
    LatLng(tree.lat, tree.lng),
  );

  void _clearNearbyTrees() => setState(() => _nearbyTreeIds = null);

  Future<void> _traceTo(MapTree tree) async {
    final start = _currentPoint;
    setState(() {
      _routeSegments = _dottedSegments(_campusCorridor(start, tree));
      _routing = true;
    });
    _mapController.move(LatLng(tree.lat, tree.lng), 17);

    try {
      final route = await _requestRoadRoute(start, LatLng(tree.lat, tree.lng));
      if (mounted && route.length > 1) {
        setState(() => _routeSegments = _dottedSegments(route));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Showing the local campus route while offline.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  List<LatLng> _campusCorridor(LatLng start, MapTree tree) {
    return [
      start,
      LatLng(start.latitude, campusCenterLng),
      LatLng(tree.lat, campusCenterLng),
      LatLng(tree.lat, tree.lng),
    ];
  }

  Future<List<LatLng>> _requestRoadRoute(
    LatLng start,
    LatLng destination,
  ) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}',
      {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw StateError('Routing unavailable');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>?;
    final geometry = routes != null && routes.isNotEmpty
        ? routes.first['geometry'] as Map<String, dynamic>?
        : null;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null) throw StateError('No route returned');
    return [
      for (final coordinate in coordinates)
        LatLng(
          ((coordinate as List<dynamic>)[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        ),
    ];
  }

  List<List<LatLng>> _dottedSegments(List<LatLng> points) {
    final segments = <List<LatLng>>[];
    for (var index = 0; index < points.length - 1; index += 2) {
      segments.add([points[index], points[index + 1]]);
    }
    return segments;
  }

  void _clearRoute() => setState(() => _routeSegments = const []);

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Runs the proximity gate, the mode choice and the manual wizard, then
  /// reflects the accepted record on the map.
  Future<void> _startVerification(MapTree tree) async {
    final record = await Navigator.of(context).push<TreeRecord>(
      MaterialPageRoute(builder: (_) => StartVerificationFlow(tree: tree)),
    );
    if (record == null || !mounted) return;

    final status = switch (record.plantStatus) {
      PlantStatus.alive => TreeStatus.pending,
      PlantStatus.damaged || PlantStatus.dead => TreeStatus.incident,
      PlantStatus.missing => TreeStatus.incident,
    };

    setState(() {
      _verifiedStatuses[tree.id] = status;
      _selectedTree = tree.copyWith(status: status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tree.id} recorded as ${record.plantStatus.label.toLowerCase()}',
        ),
        backgroundColor: EcoTraceColors.forest,
      ),
    );
  }

  void _openIncidentReport(String treeId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IncidentReportScreen(treeCode: treeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = AppConnectivityScope.statusOf(context);
    final inset = MediaQuery.paddingOf(context).top;

    // Header sits at the same y as Events / Alerts / Profile / the dashboard:
    // the status-bar inset, then the one shared gap.
    final headerTop = inset + EcoTraceHeader.topPadding;

    final scannerTop = headerTop + MapHeader.height + 18;
    final filterTop = scannerTop + 42 + 10;
    final panelTop = filterTop + 42 + 8;

    return Stack(
      children: [
        MapCanvas(
          mapController: _mapController,
          isSatellite: _satellite,
          zoneFilter: _zoneFilter,
          statusFilter: _statusFilter,
          selectedTreeId: _selectedTree?.id,
          onTreeSelected: _onTreeSelected,
          onMapTap: _onMapTap,
          trees: _displayTrees,
          gpsPoint: _currentPoint,
          heading: _currentPosition?.heading ?? 0,
          isTracking: _tracking,
          routeSegments: _routeSegments,
        ),
        Positioned(
          left: 10,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _satellite ? '© Esri' : '© OpenStreetMap',
              style: const TextStyle(
                color: Color(0xFF55685E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: headerTop,
          left: 12,
          right: 12,
          child: MapHeader(
            isSatellite: _satellite,
            connection: connection,
            onToggleLayers: () => setState(() => _satellite = !_satellite),
          ),
        ),
        Positioned(
          top: scannerTop,
          left: 12,
          child: Tooltip(
            message: _tracking ? 'Stop live tracking' : 'Track my location',
            child: _MapActionButton(
              icon: _tracking ? Icons.my_location : Icons.gps_fixed_rounded,
              label: _tracking ? 'Stop tracking' : 'Track my location',
              onTap: _toggleTracking,
              color: Colors.white,
              iconColor: _tracking
                  ? const Color(0xFF2563EB)
                  : EcoTraceColors.forest,
            ),
          ),
        ),
        Positioned(
          top: filterTop,
          left: 12,
          child: Tooltip(
            message: 'Find nearby trees',
            child: _MapActionButton(
              icon: Icons.park_outlined,
              label: 'Find nearby trees',
              onTap: _findNearbyTrees,
              color: _nearbyTreeIds == null
                  ? EcoTraceColors.forest
                  : const Color(0xFF2563EB),
            ),
          ),
        ),
        if (_nearbyTreeIds != null)
          Positioned(
            top: panelTop + 50,
            left: 12,
            child: Tooltip(
              message: 'Clear nearby tree results',
              child: _MapActionButton(
                icon: Icons.close_rounded,
                label: 'Clear nearby',
                onTap: _clearNearbyTrees,
                color: EcoTraceColors.error,
              ),
            ),
          ),
        if (_filtersOpen)
          Positioned(
            top: panelTop,
            left: 12,
            child: MapFilterPanel(
              zoneFilter: _zoneFilter,
              statusFilter: _statusFilter,
              onZoneSelected: _setZoneFilter,
              onStatusSelected: _setStatusFilter,
            ),
          ),
        Positioned(
          top: panelTop,
          left: 12,
          child: Tooltip(
            message: 'Filters',
            child: _MapActionButton(
              icon: Icons.tune_rounded,
              label: 'Filters',
              onTap: () => setState(() => _filtersOpen = !_filtersOpen),
              color: _filtersOpen || _activeFilterCount > 0
                  ? EcoTraceColors.forest
                  : Colors.white,
              iconColor: _filtersOpen || _activeFilterCount > 0
                  ? Colors.white
                  : EcoTraceColors.forest,
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: _selectedTree == null ? 92 : 330,
          child: Tooltip(
            message: 'Recenter on my location',
            child: _MapActionButton(
              icon: Icons.navigation_rounded,
              label: 'Recenter map',
              onTap: _recenter,
              color: Colors.white,
              iconColor: EcoTraceColors.forest,
            ),
          ),
        ),
        AnimatedPositioned(
          left: 12,
          right: 12,
          bottom: _selectedTree == null ? -360 : 12,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // The sheet slides over the map without invalidating the map's own
          // paint layer.
          child: RepaintBoundary(
            child: _selectedTree == null
                ? const SizedBox.shrink()
                : TreeDetailsCard(
                    tree: _selectedTree!,
                    onClose: _closeDetails,
                    onStartVerification: () =>
                        _startVerification(_selectedTree!),
                    onReportIncident: () =>
                        _openIncidentReport(_selectedTree!.id),
                    onTrace: () => _traceTo(_selectedTree!),
                    isTracing: _routing,
                    hasRoute: _routeSegments.isNotEmpty,
                    onClearRoute: _clearRoute,
                  ),
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 188,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    ),
  );
}
