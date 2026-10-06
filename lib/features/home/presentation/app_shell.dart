import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'models/local_event.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/navigation/bottom_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  Set<String> _joinedEventIds = <String>{};

  void _setJoinedEventIds(Set<String> ids) {
    setState(() => _joinedEventIds = ids);
  }

  void _leaveFromDashboard(LocalEvent event) {
    final next = {..._joinedEventIds}..remove(event.id);
    _setJoinedEventIds(next);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      EventsScreen(
        joinedEventIds: _joinedEventIds,
        onJoinedEventsChanged: _setJoinedEventIds,
      ),
      _LazyTab(active: _index == 1, builder: (context) => const MapScreen()),
      const AlertsScreen(),
      const ProfileScreen(),
      DashboardScreen(
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
          onSelected: (value) => setState(() => _index = value),
          onProgress: () => setState(() => _index = 4),
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
