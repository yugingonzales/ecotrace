import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/map_tree.dart';
import '../../painters/field_map_painter.dart';
import '../../widgets/map/gps_marker.dart';
import '../../widgets/map/map_header.dart';
import '../../widgets/map/map_label.dart';
import '../../widgets/map/map_legend.dart';
import '../../widgets/map/tree_details_card.dart';
import '../../widgets/map/tree_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _trees = [
    MapTree(
      code: 'T-104',
      species: 'Narra',
      scientificName: 'Pterocarpus indicus',
      planted: 'Jun 12, 2024',
      planter: 'CWTS Team A',
      sector: 'Sector 4-A',
      status: 'Healthy',
      dbh: '24.6 cm',
      crown: '5.2 m',
      color: Color(0xFF22C55E),
    ),
    MapTree(
      code: 'T-118',
      species: 'Molave',
      scientificName: 'Vitex parviflora',
      planted: 'May 28, 2024',
      planter: 'Green Roots Org.',
      sector: 'Sector 4-B',
      status: 'At risk',
      dbh: '18.3 cm',
      crown: '3.8 m',
      color: Color(0xFFF97316),
    ),
    MapTree(
      code: 'T-121',
      species: 'Yakal',
      scientificName: 'Shorea astylosa',
      planted: 'Jul 03, 2024',
      planter: 'CWTS Team B',
      sector: 'Sector 4-A',
      status: 'Healthy',
      dbh: '21.1 cm',
      crown: '4.6 m',
      color: Color(0xFF22C55E),
    ),
    MapTree(
      code: 'T-109',
      species: 'Unknown',
      scientificName: 'Pending',
      planted: 'Record pending',
      planter: 'Unassigned',
      sector: 'Sector 4-C',
      status: 'Unknown',
      dbh: 'Pending',
      crown: 'Pending',
      color: Color(0xFF64748B),
    ),
  ];

  MapTree? _selectedTree;

  void _selectTree(String code) {
    final tree = _trees.firstWhere((tree) => tree.code == code);
    setState(() => _selectedTree = tree);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFDDE8D9),
          child: CustomPaint(
            painter: FieldMapPainter(),
            child: Stack(
              children: [
                Positioned(
                  left: 72,
                  top: 210,
                  child: TreeMarker(
                    code: 'T-104',
                    color: const Color(0xFF22C55E),
                    onTap: () => _selectTree('T-104'),
                  ),
                ),
                Positioned(
                  left: 245,
                  top: 170,
                  child: TreeMarker(
                    code: 'T-118',
                    color: const Color(0xFFF97316),
                    onTap: () => _selectTree('T-118'),
                  ),
                ),
                Positioned(
                  left: 300,
                  top: 330,
                  child: TreeMarker(
                    code: 'T-121',
                    color: const Color(0xFF22C55E),
                    onTap: () => _selectTree('T-121'),
                  ),
                ),
                Positioned(
                  left: 140,
                  top: 370,
                  child: TreeMarker(
                    code: 'T-109',
                    color: const Color(0xFF64748B),
                    onTap: () => _selectTree('T-109'),
                  ),
                ),
                const Positioned(left: 175, top: 280, child: GpsMarker()),
              ],
            ),
          ),
        ),
        const Positioned(
          top: 132,
          left: 18,
          child: MapLabel(
            icon: Icons.forest_outlined,
            text: 'Sector 4\nReforestation Zone',
          ),
        ),
        const Positioned(
          top: 310,
          right: 18,
          child: MapLabel(
            icon: Icons.terrain_outlined,
            text: 'North\nQuadrant',
          ),
        ),
        Positioned(
          top: 132,
          left: 18,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 8),
              ],
            ),
            child: const Text(
              'N',
              style: TextStyle(
                color: EcoTraceColors.forest,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),


        Positioned(
          left: 18,
          bottom: 116,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 8),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  color: EcoTraceColors.forest,
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  '50 m',
                  style: TextStyle(
                    color: EcoTraceColors.forest,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: MapHeader(onTreeSelected: _selectTree),
        ),
        const Positioned(top: 76, right: 16, child: MapLegend()),
        AnimatedPositioned(
          left: 16,
          right: 16,
          bottom: _selectedTree == null ? -300 : 16,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _selectedTree == null
              ? const SizedBox.shrink()
              : TreeDetailsCard(
                  tree: _selectedTree!,
                  onClose: () => setState(() => _selectedTree = null),
                ),
        ),
      ],
    );
  }
}
