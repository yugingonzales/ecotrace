import 'package:flutter/material.dart';

import '../../../../../core/date/app_date.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/field_event_seed.dart';
import '../../models/local_event.dart';
import '../../widgets/events/calendar_strip.dart';
import '../../widgets/events/empty_events_state.dart';
import '../../widgets/events/event_card.dart';
import '../../widgets/events/event_details_sheet.dart';
import '../../widgets/events/full_calendar_sheet.dart';
import '../../widgets/events/participation_receipt.dart';
import '../../widgets/events/leave_confirmation_card.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/top_bar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    this.joinedEventIds = const <String>{},
    this.onJoinedEventsChanged = _ignoreJoinedEvents,
  });

  final Set<String> joinedEventIds;
  final ValueChanged<Set<String>> onJoinedEventsChanged;

  static void _ignoreJoinedEvents(Set<String> _) {}

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  /// Schedule is generated once per mount from the device's current date, so
  /// the agenda is always populated and always forward-looking.
  late final List<LocalEvent> _events = buildFieldEventSeed();

  late DateTime _selectedDay = AppDate.dayOf(
    _events.isEmpty ? DateTime.now() : _events.first.date,
  );

  /// The strip is a rolling window anchored on today, so it can never show a
  /// stale month and always offers the days the seed data lands on.
  late final DateTime _stripStart = AppDate.dayOf(DateTime.now());

  /// Six weeks of selectable days — long enough to cover the generated
  /// schedule and a week of browsing, short enough to stay cheap to lay out.
  static const int _stripSpan = 42;

  /// Lowercase search text (title + location + description) per event,
  /// computed once instead of rebuilt on every `_visibleEvents` pass.
  late final Map<String, String> _searchText = {
    for (final event in _events)
      event.id: '${event.title} ${event.location} ${event.description}'
          .toLowerCase(),
  };

  final _stripController = ScrollController();
  final _listController = ScrollController();

  /// Drives the calendar strip's collapse so it can animate in both
  /// directions instead of snapping between laid-out and zero-height.
  late final AnimationController _stripCollapse = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 200),
  );

  /// Distance the list must travel downwards before the strip collapses. The
  /// small threshold keeps over-scroll bounce near the top from hiding it.
  static const _collapseAfter = 28.0;

  /// Once the list is this close to the top the strip is always revealed,
  /// regardless of the last scroll direction.
  static const _revealAtTop = 8.0;

  bool _stripCollapsed = false;
  double _lastListPixels = 0;

  String _query = '';

  Set<String> get _joinedEvents => widget.joinedEventIds;

  /// Distinct days that actually have activities, as real dates.
  List<DateTime> get _daysWithEvents =>
      _events.map((event) => AppDate.dayOf(event.date)).toSet().toList()
        ..sort();

  List<DateTime> get _eventEndDays =>
      _events
          .map((event) => AppDate.dayOf(event.effectiveEndDate))
          .toSet()
          .toList()
        ..sort();

  List<LocalEvent> get _eventsForSelectedDay => _events
      .where((event) => AppDate.isSameDay(event.date, _selectedDay))
      .toList();

  /// Events scheduled on the selected day that satisfy the active search.
  List<LocalEvent> get _visibleEvents {
    return _events.where((event) {
      final matchesDay = AppDate.isSameDay(event.date, _selectedDay);
      final matchesQuery =
          _query.isEmpty ||
          _searchText[event.id]!.contains(_query.toLowerCase());
      return matchesDay && matchesQuery;
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
    _listController.dispose();
    _stripCollapse.dispose();
    super.dispose();
  }

  /// Returns the list to the top for a newly chosen day, which also brings
  /// the collapsed calendar strip back into view.
  void _selectDay(DateTime day) {
    setState(() => _selectedDay = AppDate.dayOf(day));
    _scrollToDay(_selectedDay);
    if (_listController.hasClients) {
      _listController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Glides the strip so the given day is centered in the visible viewport.
  void _scrollToDay(DateTime day) {
    if (!_stripController.hasClients) return;
    const itemWidth = 52.0;
    const spacing = 3.0;
    final viewport = _stripController.position.viewportDimension;
    final maxExtent = _stripController.position.maxScrollExtent;
    // The strip window starts today, so a day's offset within it is the same
    // as the offset of the date itself.
    final index = AppDate.daysBetween(_stripStart, day).clamp(0, _stripSpan);
    final desire = index * (itemWidth + spacing) + itemWidth / 2 - viewport / 2;
    final target = desire.clamp(0.0, maxExtent).toDouble();
    _stripController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Pull-to-refresh: jumps back to the current day and re-centers the strip.
  Future<void> _refresh() async {
    setState(() => _selectedDay = _stripStart);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToDay(_selectedDay);
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// Collapses the calendar strip while the user scrolls further down the
  /// list, and brings it back when they reach the very top of the list.
  ///
  bool _handleListScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    // The horizontal calendar strip is a sibling of the list rather than a
    // descendant, so its notifications never reach this listener.
    final pixels = notification.metrics.pixels;
    final delta = pixels - _lastListPixels;
    _lastListPixels = pixels;

    if (pixels <= _revealAtTop) {
      _setStripCollapsed(false);
    } else if (delta > 0 && pixels > _collapseAfter) {
      _setStripCollapsed(true);
    }
    return false;
  }

  void _setStripCollapsed(bool value) {
    if (_stripCollapsed == value) return;
    setState(() => _stripCollapsed = value);
    if (value) {
      _stripCollapse.reverse();
    } else {
      _stripCollapse.forward();
    }
  }

  /// Handles a participation request from either an event card or the details
  /// sheet, so both entry points behave identically.
  ///
  Future<void> _requestParticipation(LocalEvent event) async {
    if (_joinedEvents.contains(event.id)) {
      final confirmed = await _confirmLeave(event);
      if (!confirmed || !mounted) return;

      final next = {..._joinedEvents}..remove(event.id);
      widget.onJoinedEventsChanged(next);
      await showParticipationReceipt(context, event, leaving: true);
      return;
    }

    final confirmed = await _confirmParticipation(event);
    if (!confirmed || !mounted) return;

    final next = {..._joinedEvents}..add(event.id);
    widget.onJoinedEventsChanged(next);
    await showParticipationReceipt(context, event);
  }

  Future<bool> _confirmLeave(LocalEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x990A231C),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: LeaveConfirmationCard(
          event: event,
          onCancel: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
        ),
      ),
    );
    return confirmed ?? false;
  }

  /// Asks the user to confirm a check-in before it is recorded, summarising
  /// the event's title, time and location. Returns `false` if cancelled.
  Future<bool> _confirmParticipation(LocalEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x990A231C),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _JoinConfirmationCard(
          event: event,
          onCancel: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
        ),
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _openFullCalendar() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullCalendarSheet(
        daysWithEvents: _daysWithEvents,
        endDaysWithEvents: _eventEndDays,
        selectedDay: _selectedDay,
        onDaySelected: _selectDay,
      ),
    );
  }

  Future<void> _showDetails(LocalEvent event) async {
    final requested = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: EcoTraceColors.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => EventDetailsSheet(
        event: event,
        joined: _joinedEvents.contains(event.id),
        onConfirm: () => Navigator.pop(sheetContext, true),
      ),
    );
    if (requested == true && mounted) {
      await _requestParticipation(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _visibleEvents;
    final selectedHeading = AppDate.scheduleHeading(_selectedDay);
    final dayEventCount = _eventsForSelectedDay.length;

    return Column(
      children: [
        Container(
          key: const Key('events-header'),
          decoration: EcoTraceHeader.decoration,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                EcoTraceHeader.topPadding,
                0,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopBar(
                    onCalendar: _openFullCalendar,
                    center: SizedBox(
                      height: 36,
                      child: TextField(
                        key: const Key('events-search-field'),
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search activities...',
                          hintStyle: const TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 30,
                            maxWidth: 30,
                          ),
                          filled: true,
                          fillColor: Colors.white12,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    showSearch: false,
                    showFilter: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
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
                                selectedHeading == 'Today'
                                    ? 'Today\'s schedule'
                                    : '$selectedHeading\'s schedule',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 132),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x33A3E635),
                              border: Border.all(
                                color: const Color(0x66A3E635),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$dayEventCount ${dayEventCount == 1 ? 'activity' : 'activities'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFA3E635),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: AnimatedBuilder(
                      animation: _stripCollapse,
                      builder: (context, strip) => ClipRect(
                        key: const Key('events-calendar-collapse'),
                        child: Align(
                          heightFactor: _stripCollapse.value,
                          alignment: Alignment.topCenter,
                          child: Opacity(
                            opacity: _stripCollapse.value.clamp(0.0, 1.0),
                            child: strip,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          CalendarStrip(
                            startDay: _stripStart,
                            span: _stripSpan,
                            selectedDay: _selectedDay,
                            onSelected: _selectDay,
                            daysWithEvents: _daysWithEvents,
                            scrollController: _stripController,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _handleListScroll,
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: EcoTraceColors.forest,
                  child: ListView(
                    key: const Key('events-list'),
                    controller: _listController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    children: [
                      SectionTitle(
                        'Schedule for '
                        '${selectedHeading == 'Today' ? 'today' : selectedHeading.toLowerCase()}',
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
                            attendeeCount:
                                event.attendeeCount +
                                (_joinedEvents.contains(event.id) ? 1 : 0),
                            warm: event.warm,
                            joined: _joinedEvents.contains(event.id),
                            onOpen: () => _showDetails(event),
                            onConfirm: () => _requestParticipation(event),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JoinConfirmationCard extends StatelessWidget {
  const _JoinConfirmationCard({
    required this.event,
    required this.onCancel,
    required this.onConfirm,
  });

  final LocalEvent event;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Material(
    color: EcoTraceColors.canvas,
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [EcoTraceColors.forest, EcoTraceColors.forestDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EcoTraceColors.lemon,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: EcoTraceColors.forestDeep,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JOIN THE TEAM',
                      style: TextStyle(
                        color: EcoTraceColors.lemon,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Join this activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ready to make an impact?',
                style: TextStyle(
                  color: Color(0xFF0A231C),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Your participation pass will be issued right after you confirm.',
                style: TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EcoTraceColors.border),
                ),
                child: Column(
                  children: [
                    _ConfirmationDetail(
                      icon: Icons.forest_outlined,
                      text: event.title,
                      emphasis: true,
                    ),
                    _ConfirmationDetail(
                      icon: Icons.schedule_rounded,
                      text:
                          '${AppDate.scheduleHeading(event.date)} · ${event.time}',
                    ),
                    _ConfirmationDetail(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EcoTraceColors.forest,
                    side: const BorderSide(color: EcoTraceColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Not now'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirm joining'),
                  style: FilledButton.styleFrom(
                    backgroundColor: EcoTraceColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// One icon-and-text line inside the participation confirmation dialog.
class _ConfirmationDetail extends StatelessWidget {
  const _ConfirmationDetail({
    required this.icon,
    required this.text,
    this.emphasis = false,
  });

  final IconData icon;
  final String text;

  /// Renders the event title in the heavier body style used for headings.
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: EcoTraceColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: emphasis ? const Color(0xFF0A231C) : EcoTraceColors.muted,
              fontSize: 13,
              height: 1.35,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
