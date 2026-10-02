class LocalEvent {
  const LocalEvent({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    required this.location,
    required this.description,
    required this.attendeeCount,
    this.warm = false,
  });

  final String id;

  final DateTime date;

  final String time;
  final String title;
  final String location;
  final String description;
  final int attendeeCount;
  final bool warm;
}
