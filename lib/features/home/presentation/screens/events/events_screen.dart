import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/local_event.dart';
import '../../widgets/events/calendar_strip.dart';
import '../../widgets/events/empty_events_state.dart';
import '../../widgets/events/event_card.dart';
import '../../widgets/events/event_details_sheet.dart';
import '../../widgets/events/full_calendar_sheet.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/top_bar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  static const _events = [
    LocalEvent(
      id: 'tree-tagging',
      day: 6,
      time: '08:00 AM - 11:30 AM',
      title: 'Tree planting & tagging',
      location: 'Sector 4 Reforestation Zone',
      description:
          'Field tagging mission for native tree saplings. Bring your mobile tag verification app logged in.',
      attendeeCount: 18,
    ),
    LocalEvent(
      id: 'health-survey',
      day: 6,
      time: '01:30 PM - 03:00 PM',
      title: 'Sector 4 health survey',
      location: 'North Quadrant Field Station',
      description:
          'Canopy inspection and growth rate measurements for assigned monitoring teams.',
      attendeeCount: 12,
      warm: true,
    ),
    LocalEvent(
      id: 'audit-review',
      day: 7,
      time: '09:00 AM - 10:30 AM',
      title: 'Verification feedback review',
      location: 'EcoTrace Field Office',
      description:
          'Review returned audit feedback and resolve tree records that need a second verification pass.',
      attendeeCount: 7,
    ),
    LocalEvent(
      id: 'canopy-check',
      day: 8,
      time: '10:00 AM - 12:00 PM',
      title: 'North quadrant canopy check',
      location: 'North Quadrant Field Station',
      description:
          'Follow-up measurements for trees flagged as at risk in the latest audit cycle.',
      attendeeCount: 9,
      warm: true,
    ),
  ];

  static const int _currentDay = 6;

  final _stripController = ScrollController();

  int _selectedDay = _currentDay;
  String _query = '';
  bool _joinedOnly = false;
  final _joinedEvents = <String>{};

  List<int> get _daysWithEvents {
    return _events.map((e) => e.day).toSet().toList();
  }

  List<LocalEvent> get _visibleEvents {
    return _events.where((event) {
      final matchesDay = event.day == _selectedDay;
      final searchable =
          '${event.title} ${event.location} ${event.description}'.toLowerCase();
      final matchesQuery =
          _query.isEmpty || searchable.contains(_query.toLowerCase());
      final matchesJoined = !_joinedOnly || _joinedEvents.contains(event.id);
      return matchesDay && matchesQuery && matchesJoined;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToDay(_selectedDay);
    });
  }

  @override
  void dispose() {
    _stripController.dispose();
    super.dispose();
  }

  /// Glides the strip so the given day is centered in the visible viewport.
  void _scrollToDay(int day) {
    if (!_stripController.hasClients) return;
    const itemWidth = 56.0;
    const spacing = 4.0;
    final viewport = _stripController.position.viewportDimension;
    final maxExtent = _stripController.position.maxScrollExtent;
    final desire =
        (day - 1) * (itemWidth + spacing) + itemWidth / 2 - viewport / 2;
    final target = desire.clamp(0.0, maxExtent).toDouble();
    _stripController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Pull-to-refresh: jumps back to the current day and re-centers the strip.
  Future<void> _refresh() async {
    setState(() => _selectedDay = _currentDay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToDay(_selectedDay);
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _openFullCalendar() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullCalendarSheet(
        daysWithEvents: _daysWithEvents,
        selectedDay: _selectedDay,
        onDaySelected: (day) {
          setState(() => _selectedDay = day);
          _scrollToDay(day);
        },
      ),
    );
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _query);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search field activities'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search title or location',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (value != null && mounted) setState(() => _query = value.trim());
  }

  Future<void> _openFilter() async {
    final joinedOnly = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: EcoTraceColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5DFD8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter activities',
                    style: TextStyle(
                      color: Color(0xFF0A231C),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _joinedOnly,
                    onChanged: (value) {
                      Navigator.pop(sheetContext, value ?? false);
                    },
                    title: const Text(
                      'Show only joined',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, _joinedOnly),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (joinedOnly != null && mounted) {
      setState(() => _joinedOnly = joinedOnly);
    }
  }

  void _toggleJoined(LocalEvent event) {
    setState(() {
      if (_joinedEvents.contains(event.id)) {
        _joinedEvents.remove(event.id);
      } else {
        _joinedEvents.add(event.id);
      }
    });
  }

  void _showDetails(LocalEvent event) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EcoTraceColors.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => EventDetailsSheet(
        event: event,
        joined: _joinedEvents.contains(event.id),
        onConfirm: () {
          Navigator.pop(sheetContext);
          _toggleJoined(event);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _visibleEvents;

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D6E4F), Color(0xFF05291D)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopBar(
                    onSearch: _openSearch,
                    onFilter: _openFilter,
                    onCalendar: _openFullCalendar,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FIELD ACTIVITIES',
                              style: TextStyle(
                                color: EcoTraceColors.lemon,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Today\'s schedule',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33A3E635),
                          border: Border.all(color: const Color(0x66A3E635)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '3 active today',
                          style: TextStyle(
                            color: Color(0xFFA3E635),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CalendarStrip(
                    selectedDay: _selectedDay,
                    onSelected: (day) {
                      setState(() => _selectedDay = day);
                      _scrollToDay(day);
                    },
                    daysWithEvents: _daysWithEvents,
                    scrollController: _stripController,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: EcoTraceColors.forest,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
              SectionTitle(
                'Schedule for ${_selectedDay == 6 ? 'today' : 'Sep $_selectedDay'}',
              ),
              if (visibleEvents.isEmpty)
                const EmptyEventsState()
              else
                ...visibleEvents.map(
                  (event) => EventCard(
                    time: event.time,
                    title: event.title,
                    location: event.location,
                    description: event.description,
                    attendeeCount: event.attendeeCount +
                        (_joinedEvents.contains(event.id) ? 1 : 0),
                    warm: event.warm,
                    joined: _joinedEvents.contains(event.id),
                    onOpen: () => _showDetails(event),
                    onConfirm: () => _toggleJoined(event),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



