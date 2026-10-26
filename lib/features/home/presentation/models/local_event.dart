import 'dart:convert';

const defaultMonitoringMetrics = <String>[
  'GPS Coordinates',
  'Status Photo',
  'Tree Height (cm)',
  'Growth Stage',
  'Diameter Measurement (cm)',
  'Survival Status',
];

class LocalEvent {
  const LocalEvent({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    required this.location,
    required this.description,
    required this.attendeeCount,
    this.endDate,
    this.targetTrees = 0,
    this.verifiedTrees = 0,
    this.monitoringMetrics = defaultMonitoringMetrics,
    this.boundary = const <List<double>>[],
    this.warm = false,
  });

  final String id;

  final DateTime date;

  final String time;
  final String title;
  final String location;
  final String description;
  final int attendeeCount;

  /// Total trees assigned to this event. This is optional for legacy schedule
  /// entries and is supplied by the event seed/API when available.
  final int targetTrees;

  /// Trees verified by the current staff member for this event.
  final int verifiedTrees;
  final List<String> monitoringMetrics;

  /// Persisted event geofence as [latitude, longitude] vertices.
  final List<List<double>> boundary;

  /// The final day of the activity. A missing value means the activity is
  /// scheduled for one day only.
  final DateTime? endDate;

  DateTime get effectiveEndDate => endDate ?? date;
  bool get spansMultipleDays =>
      effectiveEndDate.year != date.year ||
      effectiveEndDate.month != date.month ||
      effectiveEndDate.day != date.day;

  final bool warm;

  factory LocalEvent.fromApi(Map<String, dynamic> json) {
    DateTime parseDate(String value) {
      final parts = value.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }

    final start = parseDate(json['start_date'] as String);
    final end = parseDate(json['end_date'] as String);
    final rawBoundary = json['event_boundary'];
    final boundary = rawBoundary is String
        ? (jsonDecode(rawBoundary) as List<dynamic>? ?? const <dynamic>[])
        : rawBoundary;
    final rawMetrics = json['monitoring_metrics'];
    final metrics = rawMetrics is String
        ? (jsonDecode(rawMetrics) as List<dynamic>? ?? const <dynamic>[])
        : rawMetrics;
    return LocalEvent(
      id: 'api-${json['event_id']}',
      date: start,
      endDate: end,
      time: 'All day',
      title: json['event_title'] as String? ?? 'EcoTrace event',
      location:
          (json['event_location'] as String?) ??
          (json['event_zone'] as String?) ??
          'EcoTrace field site',
      description: json['event_description'] as String? ?? '',
      attendeeCount: (json['attendee_count'] as num?)?.toInt() ?? 0,
      targetTrees: (json['trees_per_student'] as num?)?.toInt() ?? 0,
      verifiedTrees: (json['verified_trees'] as num?)?.toInt() ?? 0,
      monitoringMetrics: metrics is List
          ? metrics.whereType<String>().toList()
          : defaultMonitoringMetrics,
      boundary: boundary is List
          ? boundary.whereType<List>().map((point) => point.map((value) => (value as num).toDouble()).toList()).where((point) => point.length == 2).toList()
          : const <List<double>>[],
    );
  }
}
