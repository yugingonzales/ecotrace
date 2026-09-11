import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'nav_item.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.onScan,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      height: 86,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: NavItem(
                  index: 0,
                  icon: Icons.event_outlined,
                  label: 'Events',
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: NavItem(
                  index: 1,
                  icon: Icons.map_outlined,
                  label: 'Map',
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: Offset(0, compact ? -7 : -11),
                child: SizedBox(
                  width: compact ? 52 : 64,
                  height: compact ? 52 : 64,
                  child: FloatingActionButton(
                    onPressed: onScan,
                    backgroundColor: EcoTraceColors.lemon,
                    foregroundColor: EcoTraceColors.forest,
                    elevation: 8,
                    shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 4),
                    ),
                    tooltip: 'Start tree verification',
                    child: Icon(Icons.add_rounded, size: compact ? 30 : 38),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: NavItem(
                  index: 3,
                  icon: Icons.notifications_none_rounded,
                  label: 'Alerts',
                  badge: '2',
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: NavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  compact: compact,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
