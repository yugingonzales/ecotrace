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

  /// The final day of the activity. A missing value means the activity is
  /// scheduled for one day only.
  final DateTime? endDate;

  DateTime get effectiveEndDate => endDate ?? date;
  bool get spansMultipleDays =>
      effectiveEndDate.year != date.year ||
      effectiveEndDate.month != date.month ||
      effectiveEndDate.day != date.day;

  final bool warm;
}
