import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
import '../scanner/scanner_screen.dart';
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
  String? _zoneFilter;
  TreeStatus? _statusFilter;
  MapTree? _selectedTree;

  /// In-session status overrides keyed by tree id. There is no database yet,
  /// so a completed verification updates the map immediately and the change
  /// lives only as long as the app does. A real backend replaces this map.
  final Map<String, TreeStatus> _verifiedStatuses = {};

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

  void _recenter() => _mapController.move(_gpsPoint, 16);

  /// Scanning a tag is a way of *finding* a tree, not of verifying one, so it
  /// sits on the map chrome rather than inside the verification flow. Its
  /// manual-entry sheet is still the old single-page form; the verification
  /// wizard supersedes it but the two are not merged yet.
  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  /// Runs the proximity gate, the mode choice and the manual wizard, then
  /// reflects the accepted record on the map.
  Future<void> _startVerification(MapTree tree) async {
    final record = await Navigator.of(context).push<TreeRecord>(
      MaterialPageRoute(
        builder: (_) => StartVerificationFlow(tree: tree),
      ),
    );
    if (record == null || !mounted) return;

    // A dead or missing plant is an incident on the map; a healthy sighting
    // completes the verification. Both go to "Pending" in the first cut
    // because nothing reviews the record yet.
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
    return Stack(
      children: [
        // The map canvas is memoized: chrome interactivity below (header,
        // filters, details sheet) rebuilds only this Stack's overlay widgets,
        // never the FlutterMap + tile + marker subtree.
        MapCanvas(
          mapController: _mapController,
          isSatellite: _satellite,
          zoneFilter: _zoneFilter,
          statusFilter: _statusFilter,
          selectedTreeId: _selectedTree?.id,
          onTreeSelected: _onTreeSelected,
          onMapTap: _onMapTap,
          trees: _trees,
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
          top: 12,
          left: 12,
          right: 12,
          child: MapHeader(
            isSatellite: _satellite,
            connection: connection,
            onToggleLayers: () => setState(() => _satellite = !_satellite),
          ),
        ),
        Positioned(
          top: 80,
          right: 12,
          child: Tooltip(
            message: 'Scan a tree tag',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openScanner,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x26000000), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: EcoTraceColors.forest,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 132,
          right: 12,
          child: Tooltip(
            message: 'Filters',
            child: MapFilterButton(
              open: _filtersOpen,
              activeFilterCount: _activeFilterCount,
              onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            ),
          ),
        ),
        if (_filtersOpen)
          Positioned(
            top: 182,
            right: 12,
            child: MapFilterPanel(
              zoneFilter: _zoneFilter,
              statusFilter: _statusFilter,
              onZoneSelected: _setZoneFilter,
              onStatusSelected: _setStatusFilter,
            ),
          ),
        Positioned(
          right: 12,
          bottom: _selectedTree == null ? 92 : 330,
          child: Tooltip(
            message: 'Recenter on campus',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _recenter,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x26000000), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: EcoTraceColors.forest,
                    size: 22,
                  ),
                ),
              ),
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
                  ),
          ),
        ),
      ],
    );
  }
}
