import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/scanner/scanner_screen.dart';
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
    const pages = <Widget>[
      EventsScreen(),
      MapScreen(),
      SizedBox.shrink(),
      AlertsScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: EcoTraceColors.canvas,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
        onScan: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen())),
      ),
    );
  }
}

