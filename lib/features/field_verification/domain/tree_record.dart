/// Observational status of a plant, as recorded by a field officer.
///
enum PlantStatus { alive, damaged, dead, missing }

extension PlantStatusX on PlantStatus {
  /// Field-facing label, using the vocabulary the monitoring team uses.
  String get label => switch (this) {
    PlantStatus.alive => 'Alive',
    PlantStatus.damaged => 'Damaged',
    PlantStatus.dead => 'Dead',
    PlantStatus.missing => 'Missing',
  };

  /// Longer explanation shown under the label while choosing.
  String get description => switch (this) {
    PlantStatus.alive => 'Standing and observable',
    PlantStatus.damaged => 'Standing, but visibly broken or harmed',
    PlantStatus.dead => 'Standing but no longer alive',
    PlantStatus.missing => 'No plant found at the recorded location',
  };

  /// A missing plant cannot be measured or photographed, so the wizard skips
  /// both the measurement and the evidence steps for it.

  /// This is a domain rule, not a UI nicety: requiring a photo of a tree that
  /// is not there would train staff to fabricate evidence.
  bool get requiresEvidence => this != PlantStatus.missing;

  bool get requiresMeasurements => this != PlantStatus.missing;
}

enum VerificationStatus { draft, pending, verified, rejected, conflict }

enum MeasurementSource { automated, manual, corrected }

/// A completed field verification of one tree.
///
class TreeRecord {
  const TreeRecord({
    required this.treeId,
    required this.treeCode,
    required this.species,
    required this.latitude,
    required this.longitude,
    required this.plantStatus,
    required this.verificationStatus,
    required this.measurementSource,
    this.dbhCm,
    this.crownDimensionCm,
    this.notes,
    this.photoEvidence = const [],
    this.verifiedByStaffId,
    this.verifiedAt,
    this.distanceFromTreeMeters,
  });

  final String treeId;
  final String treeCode;
  final String species;
  final double latitude;
  final double longitude;

  /// Null when [plantStatus] is [PlantStatus.missing] — there was nothing to
  /// measure, and a number would be a fabrication rather than an observation.
  final double? dbhCm;

  /// Null when [plantStatus] is [PlantStatus.missing], for the same reason.
  final double? crownDimensionCm;

  final PlantStatus plantStatus;
  final VerificationStatus verificationStatus;
  final MeasurementSource measurementSource;
  final String? notes;

  /// File paths of the camera captures. Empty for a missing plant.
  final List<String> photoEvidence;

  final String? verifiedByStaffId;
  final DateTime? verifiedAt;

  final double? distanceFromTreeMeters;
}
