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
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/top_bar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

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
  bool _joinedOnly = false;
  final _joinedEvents = <String>{};

  /// Distinct days that actually have activities, as real dates.
  List<DateTime> get _daysWithEvents => _events
      .map((event) => AppDate.dayOf(event.date))
      .toSet()
      .toList()
    ..sort();

  /// Every event on the selected day, ignoring the search and joined-only
  /// filters. The header count reflects what's actually scheduled rather than
  /// how many survived filtering.
  List<LocalEvent> get _eventsForSelectedDay => _events
      .where((event) => AppDate.isSameDay(event.date, _selectedDay))
      .toList();

  /// Events scheduled on the selected day that also satisfy the active
  /// search and joined-only filters.
  List<LocalEvent> get _visibleEvents {
    return _events.where((event) {
      final matchesDay = AppDate.isSameDay(event.date, _selectedDay);
      final matchesQuery =
          _query.isEmpty ||
          _searchText[event.id]!.contains(_query.toLowerCase());
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
    const itemWidth = 56.0;
    const spacing = 4.0;
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

  Future<void> _openFullCalendar() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullCalendarSheet(
        daysWithEvents: _daysWithEvents,
        selectedDay: _selectedDay,
        onDaySelected: (day) {
          _selectDay(day);
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

  /// Collapses the calendar strip while the user scrolls further down the
  /// list, and brings it back when they reach the very top of the list.
  ///
  /// The strip is deliberately *not* restored on an upward nudge: with many
  /// event cards on screen the user wants the space back, so it stays out of
  /// the way for the whole length of the list. The gap between
  /// [_revealAtTop] and [_collapseAfter] keeps overscroll near the top from
  /// flickering the header.
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
  /// Joining requires confirmation first and then issues a floating
  /// participation receipt. Leaving an activity that is already joined stays a
  /// silent toggle, since that is a withdrawal rather than a check-in.
  Future<void> _requestParticipation(LocalEvent event) async {
    if (_joinedEvents.contains(event.id)) {
      setState(() => _joinedEvents.remove(event.id));
      return;
    }

    final confirmed = await _confirmParticipation(event);
    if (!confirmed || !mounted) return;

    setState(() => _joinedEvents.add(event.id));
    await showParticipationReceipt(context, event);
  }

  /// Asks the user to confirm a check-in before it is recorded, summarising
  /// the event's title, time and location. Returns `false` if cancelled.
  Future<bool> _confirmParticipation(LocalEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: EcoTraceColors.canvas,
        title: const Text('Confirm participation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to join this field activity. A participation pass '
              'will be issued on confirmation.',
            ),
            const SizedBox(height: 16),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enter event'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showDetails(LocalEvent event) async {
    // The sheet only reports that participation was requested; the actual
    // confirm-then-receipt flow is shared with the event cards so both entry
    // points behave identically.
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
              padding: const EdgeInsets.fromLTRB(
                20,
                EcoTraceHeader.topPadding,
                20,
                16,
              ),
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
                              selectedHeading == 'Today'
                                  ? 'Today\'s schedule'
                                  : '$selectedHeading\'s schedule',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        // The count is secondary to the title. On a 320dp
                        // viewport an unconstrained badge laid out first and
                        // took the whole row, squeezing the Expanded title to
                        // a few pixels and wrapping it over 400px. Capping it
                        // keeps the title readable at any width.
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: Container(
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
                  // The strip animates away as the user scrolls into the
                  // schedule, handing ~96px back to the list so long days of
                  // event cards stay readable. AnimatedBuilder is required
                  // here: setState alone would only rebuild once, before the
                  // controller had advanced.
                  //
                  // The 18px gap sits *inside* the collapsed child deliberately.
                  // As a sibling it never animated away, so hiding the strip
                  // still left 18px of gap plus the 16px header bottom padding
                  // = 34px of dead green under the title. Collapsing both leaves
                  // the intended 16px.
                  AnimatedBuilder(
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
                        const SizedBox(height: 18),
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
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
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
        ),
      ],
    );
  }
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
