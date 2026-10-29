import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_client.dart';
import 'data/event_client.dart';
import 'models/local_event.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/navigation/bottom_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.user});

  final User? user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 4;
  bool _joinedRefreshInProgress = false;
  Set<String> _joinedEventIds = <String>{};
  List<LocalEvent> _joinedEvents = <LocalEvent>[];
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadJoinedEvents();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshJoinedEvents();
  }

  Future<void> _refreshJoinedEvents() async {
    if (_joinedRefreshInProgress) return;
    _joinedRefreshInProgress = true;
    try {
      await _loadJoinedEvents();
    } finally {
      _joinedRefreshInProgress = false;
    }
  }

  Future<void> _loadJoinedEvents() async {
    try {
      final events = await EventClient.joined();
      if (!mounted) return;
      setState(() {
        _joinedEvents = events;
        _joinedEventIds = events.map((event) => event.id).toSet();
      });
    } catch (_) {}
  }

  void _setJoinedEventIds(Set<String> ids) {
    setState(() {
      _joinedEventIds = ids;
      _joinedEvents = _joinedEvents
          .where((event) => ids.contains(event.id))
          .toList();
    });
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    if (index == 0 || index == 4) _refreshJoinedEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _leaveFromDashboard(LocalEvent event) {
    final next = {..._joinedEventIds}..remove(event.id);
    _setJoinedEventIds(next);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      EventsScreen(
        active: _index == 0,
        joinedEventIds: _joinedEventIds,
        onJoinedEventsChanged: _setJoinedEventIds,
      ),
      _LazyTab(active: _index == 1, builder: (context) => const MapScreen()),
      AlertsScreen(
        isOpen: _index == 2,
        onUnreadCountChanged: (count) {
          if (mounted) setState(() => _unreadNotificationCount = count);
        },
      ),
      ProfileScreen(user: widget.user),
      DashboardScreen(
        events: _joinedEvents,
        joinedEventIds: _joinedEventIds,
        onLeave: _leaveFromDashboard,
        onMap: () => setState(() => _index = 1),
      ),
    ];
    final dashboardSelected = _index == 4;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dashboardSelected
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: dashboardSelected
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: EcoTraceColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: EcoTraceColors.canvas,
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: BottomNavigation(
          selectedIndex: _index,
          onSelected: _selectTab,
          onProgress: () => _selectTab(4),
          unreadCount: _unreadNotificationCount,
        ),
      ),
    );
  }
}

/// Builds its child only while `active`, then keeps it alive forever after.
///
class _LazyTab extends StatefulWidget {
  const _LazyTab({required this.active, required this.builder});

  final bool active;
  final WidgetBuilder builder;

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> {
  Widget? _cached;

  @override
  Widget build(BuildContext context) {
    final cached = _cached;
    if (cached != null) return cached;
    if (!widget.active) return const SizedBox.shrink();
    return _cached = widget.builder(context);
  }
}
