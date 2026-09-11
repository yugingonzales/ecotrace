import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class NavItem extends StatelessWidget {
  const NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.selectedIndex,
    required this.onSelected,
    required this.compact,
    this.badge,
    super.key,
  });

  final int index;
  final IconData icon;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final active = selectedIndex == index;
    return InkWell(
      onTap: () => onSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: compact ? 25 : 28,
                  color: active ? EcoTraceColors.forest : EcoTraceColors.muted,
                ),
                if (badge != null)
                  Positioned(
                    right: -9,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? EcoTraceColors.forest : EcoTraceColors.muted,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
