import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/connectivity/app_connectivity_scope.dart';
import '../../../../../core/connectivity/connection_status.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/campus_data.dart';
import '../../models/map_tree.dart';
import '../../widgets/map/map_canvas.dart';
import '../../widgets/map/map_filter_panel.dart';
import '../../widgets/map/map_header.dart';
import '../../widgets/map/tree_details_card.dart';
import '../incident/incident_report_screen.dart';
import '../scanner/scanner_screen.dart';

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

  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
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
            isOnline: connection == ConnectionStatus.online,
            onToggleLayers: () => setState(() => _satellite = !_satellite),
          ),
        ),
        Positioned(
          top: 80,
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
            top: 130,
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
                    onStartVerification: _openScanner,
                    onReportIncident: () =>
                        _openIncidentReport(_selectedTree!.id),
                  ),
          ),
        ),
      ],
    );
  }
}
