import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../monitoring_progress/presentation/monitoring_progress_screen.dart';
import 'screens/alerts/alerts_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const EventsScreen(),
      // The map subtree is the heaviest tab: `FlutterMap` construction, the
      // initial `CameraFit.bounds`, tile warm-up and 23 marker layers. Its
      // slot is `active` only while the Map tab is on screen, so the shell
      // never inflates it on login or while other tabs are active; after the
      // first visit the built subtree is cached and kept mounted, so tab
      // switching stays instant and the map keeps its state.
      _LazyTab(active: _index == 1, builder: (context) => const MapScreen()),
      const SizedBox.shrink(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: EcoTraceColors.canvas,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
        onProgress: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MonitoringProgressScreen(),
          ),
        ),
      ),
    );
  }
}

/// Builds its child only while `active`, then keeps it alive forever after.
///
/// The shell's tab slots are eagerly mounted by `IndexedStack` (offstage when
/// not selected), so a plain one-shot child would still inflate the heavy map
/// at startup. Gating on `active` defers the first construction until the tab
/// is actually on screen; after that, the same cached widget instance is
/// returned on every rebuild, so the mounted subtree (and its state) survives
/// tab switches without being rebuilt.
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
