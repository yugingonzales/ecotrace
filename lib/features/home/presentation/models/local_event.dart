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
    this.warm = false,
  });

  final String id;

  final DateTime date;

  final String time;
  final String title;
  final String location;
  final String description;
  final int attendeeCount;

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
