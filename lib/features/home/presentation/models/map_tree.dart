import 'package:flutter/material.dart';

/// The only offline/mock inventory shared by the mobile map and its filters.
/// Coordinates mirror the web fallback in `src/lib/trees.js`.
const List<MapTree> fallbackTestTrees = [
  MapTree(
    id: 'TEST-TREE-01',
    lat: 12.5098,
    lng: 124.6676,
    status: TreeStatus.verified,
    planter: 'Test Staff 1',
    species: 'Narra',
    datePlanted: 'Mar 12, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TEST-TREE-02',
    lat: 12.5131,
    lng: 124.6614,
    status: TreeStatus.pending,
    planter: 'Test Staff 2',
    species: 'Molave',
    datePlanted: 'Mar 15, 2026',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TEST-TREE-03',
    lat: 12.5103,
    lng: 124.6609,
    status: TreeStatus.unverified,
    planter: 'Test Staff 3',
    species: 'Ipil',
    datePlanted: 'Mar 18, 2026',
    zone: 'Zone III',
  ),
  MapTree(
    id: 'TEST-TREE-04',
    lat: 12.5118,
    lng: 124.6647,
    status: TreeStatus.incident,
    planter: 'Test Staff 4',
    species: 'Mahogany',
    datePlanted: 'Mar 21, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TEST-TREE-05',
    lat: 12.5095,
    lng: 124.6628,
    status: TreeStatus.verified,
    planter: 'Test Staff 5',
    species: 'Kamagong',
    datePlanted: 'Mar 24, 2026',
    zone: 'Zone III',
  ),
];

/// Stand-in documentation photo used for every tree until the admin portal
/// ships real per-tree imagery. Already bundled via `pubspec.yaml` assets.
const String kPlaceholderTreePhoto = 'lib/assets/icons/ecotrace_icon.png';

/// Status vocabulary shared with the EcoTrace admin portal tree inventory
/// (`trees.ts` `StatusKey`).
enum TreeStatus { verified, pending, incident, unverified }

extension TreeStatusX on TreeStatus {
  /// Human-readable label, matching the admin portal's legend.
  String get label => switch (this) {
    TreeStatus.verified => 'Verified',
    TreeStatus.pending => 'Pending',
    TreeStatus.incident => 'Incident',
    TreeStatus.unverified => 'Unverified',
  };

  /// Marker/pill color, matching the admin portal (`trees.ts` `STATUS` map).
  Color get color => switch (this) {
    TreeStatus.verified => const Color(0xFF2F9E6E),
    TreeStatus.pending => const Color(0xFFD9902B),
    TreeStatus.incident => const Color(0xFFDC3A3A),
    TreeStatus.unverified => const Color(0xFF9AA1A9),
  };
}

/// A georeferenced tree from the admin portal inventory.

/// Mirrors the admin `TreeMarker` shape so the Flutter map renders the exact
/// real-world coordinates, statuses and zone membership of UEP Catarman.
class MapTree {
  factory MapTree.fromApi(Map<String, dynamic> json) {
    final status = switch (json['tree_status'] as String? ?? 'unverified') {
      'verified' => TreeStatus.verified,
      'pending' => TreeStatus.pending,
      'incident' => TreeStatus.incident,
      _ => TreeStatus.unverified,
    };
    final date = json['tree_planted_date'] as String? ?? '';
    final parts = date.split('-');
    final displayDate = parts.length == 3
        ? '${_monthName(int.tryParse(parts[1]) ?? 0)} ${int.tryParse(parts[2]) ?? 0}, ${parts[0]}'
        : date;
    return MapTree(
      id: json['tree_code'] as String? ?? '',
      lat: (json['latitude'] as num).toDouble(),
      lng: (json['longitude'] as num).toDouble(),
      status: status,
      planter: json['tree_planter_name'] as String? ?? 'Unassigned',
      species: json['tree_name'] as String? ?? 'Unknown species',
      datePlanted: displayDate,
      zone: json['zone_name'] as String? ?? 'Zone I',
    );
  }

  static String _monthName(int month) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month.clamp(0, 12)];

  const MapTree({
    required this.id,
    required this.lat,
    required this.lng,
    required this.status,
    required this.planter,
    required this.species,
    required this.datePlanted,
    required this.zone,
    this.photos = const [],
  });

  /// Admin tree tag, e.g. `TRE-0892`.
  final String id;

  final double lat;
  final double lng;
  final TreeStatus status;

  /// Staff member responsible for the tree (admin `staffName`).
  final String planter;

  final String species;

  /// Human-readable planted date, e.g. `Mar 12, 2026`.
  final String datePlanted;

  /// `Zone I` | `Zone II` | `Zone III`.
  final String zone;

  /// Documentation photos for this planted tree.
  final List<String> photos;

  Color get color => status.color;
  String get statusLabel => status.label;

  /// Compact coordinate pair shown in the details card, e.g. `12.5101, 124.6679`.
  String get coordinates =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  /// Photos guaranteed non-empty for the UI, so widgets never guard on `isEmpty`.
  /// Every tree currently shares the EcoTrace placeholder badge until the admin
  /// portal starts shipping real per-tree documentation photos.
  List<String> get photosList =>
      photos.isNotEmpty ? photos : const [kPlaceholderTreePhoto];

  /// Returns a copy with the given fields replaced. Used to reflect a field
  /// verification in the map without mutating the shared const inventory.
  MapTree copyWith({
    double? lat,
    double? lng,
    TreeStatus? status,
    String? species,
    String? zone,
    String? planter,
    String? datePlanted,
    List<String>? photos,
  }) => MapTree(
    id: id,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    status: status ?? this.status,
    planter: planter ?? this.planter,
    species: species ?? this.species,
    datePlanted: datePlanted ?? this.datePlanted,
    zone: zone ?? this.zone,
    photos: photos ?? this.photos,
  );
}
