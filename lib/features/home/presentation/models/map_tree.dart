import 'package:flutter/material.dart';

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
///
/// Mirrors the admin `TreeMarker` shape so the Flutter map renders the exact
/// real-world coordinates, statuses and zone membership of UEP Catarman.
class MapTree {
  const MapTree({
    required this.id,
    required this.lat,
    required this.lng,
    required this.status,
    required this.planter,
    required this.species,
    required this.datePlanted,
    required this.zone,
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

  Color get color => status.color;
  String get statusLabel => status.label;

  /// Compact coordinate pair shown in the details card, e.g. `12.5101, 124.6679`.
  String get coordinates => '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}
