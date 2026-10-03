import '../models/local_event.dart';

/// Offline schedule used until a real events endpoint exists.

/// The list is built once per session from a single "today" so that every
/// event shares one consistent origin.
List<LocalEvent> buildFieldEventSeed({DateTime? now}) {
  final today = DateTime(
    (now ?? DateTime.now()).year,
    (now ?? DateTime.now()).month,
    (now ?? DateTime.now()).day,
  );
  DateTime on(int offset) => today.add(Duration(days: offset));

  return [
    LocalEvent(
      id: 'tree-tagging',
      date: on(0),
      time: '08:00 AM - 11:30 AM',
      title: 'Tree planting & tagging',
      location: 'Sector 4 Reforestation Zone',
      description: 'Field tagging mission for native tree saplings. Bring your mobile tag verification app logged in.',
      attendeeCount: 18,
      endDate: on(1),
    ),
    LocalEvent(
      id: 'health-survey',
      date: on(0),
      time: '01:30 PM - 03:00 PM',
      title: 'Sector 4 health survey',
      location: 'North Quadrant Field Station',
      description: 'Canopy inspection and growth rate measurements for assigned monitoring teams.',
      attendeeCount: 12,
      warm: true,
    ),
    LocalEvent(
      id: 'audit-review',
      date: on(1),
      time: '09:00 AM - 10:30 AM',
      title: 'Verification feedback review',
      location: 'EcoTrace Field Office',
      description: 'Review returned audit feedback and resolve tree records that need a second verification pass.',
      attendeeCount: 7,
    ),
    LocalEvent(
      id: 'canopy-check',
      date: on(2),
      time: '10:00 AM - 12:00 PM',
      title: 'North quadrant canopy check',
      location: 'North Quadrant Field Station',
      description: 'Follow-up measurements for trees flagged as at risk in the latest audit cycle.',
      attendeeCount: 9,
      warm: true,
    ),
  ];
}
