enum PlantStatus { healthy, atRisk, damaged, missing, unknown }

enum VerificationStatus { draft, pending, verified, rejected, conflict }

enum MeasurementSource { automated, manual, corrected }

class TreeRecord {
  const TreeRecord({
    required this.treeId,
    required this.treeCode,
    required this.species,
    required this.latitude,
    required this.longitude,
    required this.dbh,
    required this.crownDimension,
    required this.plantStatus,
    required this.verificationStatus,
    required this.measurementSource,
    this.notes,
    this.photoEvidence,
    this.verifiedByStaffId,
    this.verifiedAt,
  });

  final String treeId;
  final String treeCode;
  final String species;
  final double latitude;
  final double longitude;
  final double dbh;
  final double crownDimension;
  final PlantStatus plantStatus;
  final VerificationStatus verificationStatus;
  final MeasurementSource measurementSource;
  final String? notes;
  final String? photoEvidence;
  final String? verifiedByStaffId;
  final DateTime? verifiedAt;
}
