class LocalEvent {
  const LocalEvent({
    required this.id,
    required this.day,
    required this.time,
    required this.title,
    required this.location,
    required this.description,
    required this.attendeeCount,
    this.warm = false,
  });

  final String id;
  final int day;
  final String time;
  final String title;
  final String location;
  final String description;
  final int attendeeCount;
  final bool warm;
}
