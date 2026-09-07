import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class CalendarStrip extends StatelessWidget {
  const CalendarStrip({
    super.key,
    required this.selectedDay,
    required this.onSelected,
    this.daysWithEvents = const [],
    this.scrollController,
    this.itemWidth = 56,
    this.spacing = 4,
  });

  final int selectedDay;
  final ValueChanged<int> onSelected;
  final List<int> daysWithEvents;
  final ScrollController? scrollController;
  final double itemWidth;
  final double spacing;

  /// Days available to scroll through (September 2026, Mon 1st - Sun 30th).
  static final List<int> _days = List<int>.generate(
    30,
    (i) => i + 1,
    growable: false,
  );

  /// The weekday label for a day in September 2026 (the 1st was a Monday).
  static String _weekday(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(day - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EcoTraceColors.forestDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 70,
        child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: _days.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final day = _days[index];
          return InkWell(
            onTap: () => onSelected(day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: day == selectedDay
                    ? EcoTraceColors.lemon
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(day),
                    style: TextStyle(
                      color: day == selectedDay
                          ? const Color(0xFF0A231C)
                          : const Color(0xFFA3B8AC),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$day',
                    style: TextStyle(
                      color: day == selectedDay
                          ? const Color(0xFF0A231C)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: daysWithEvents.contains(day)
                          ? (day == selectedDay
                              ? const Color(0xFF0A231C)
                              : EcoTraceColors.lemon)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}




