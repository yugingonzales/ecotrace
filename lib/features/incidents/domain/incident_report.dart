enum IncidentType { damaged, missing, other }

enum IncidentSeverity { low, medium, high }

enum IncidentStatus { draft, queued, submitted, resolved, failed }

class IncidentReport {
  const IncidentReport({
    required this.incidentId,
    required this.treeId,
    required this.reportedByStaffId,
    required this.incidentType,
    required this.severity,
    required this.description,
    required this.reportedAt,
    required this.status,
    this.latitude,
    this.longitude,
    this.photoEvidence,
  });

  final String incidentId;
  final String treeId;
  final String reportedByStaffId;
  final IncidentType incidentType;
  final IncidentSeverity severity;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? photoEvidence;
  final DateTime reportedAt;
  final IncidentStatus status;
}
