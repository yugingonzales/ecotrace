import 'package:flutter/material.dart';

import '../../../../../core/date/app_date.dart';
import '../../../../../core/theme/app_theme.dart';

/// Horizontally scrolling run of selectable days starting at [startDay].
///
/// The window is anchored on a real date rather than a hard-coded list of
/// day numbers, so weekdays, month boundaries and the "today" marker are all
/// derived from the calendar instead of assumed.
class CalendarStrip extends StatelessWidget {
  const CalendarStrip({
    super.key,
    required this.startDay,
    required this.selectedDay,
    required this.onSelected,
    this.span = 42,
    this.daysWithEvents = const [],
    this.scrollController,
    this.itemWidth = 56,
    this.spacing = 4,
  });

  /// First day in the window, normally today.
  final DateTime startDay;

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  /// Number of selectable days offered.
  final int span;

  final List<DateTime> daysWithEvents;
  final ScrollController? scrollController;
  final double itemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final today = AppDate.dayOf(DateTime.now());
    final first = AppDate.dayOf(startDay);
    final days = List<DateTime>.generate(
      span,
      (index) => first.add(Duration(days: index)),
      growable: false,
    );
    final eventDays = daysWithEvents
        .map(AppDate.dayOf)
        .toSet();

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
        itemCount: days.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = AppDate.isSameDay(day, selectedDay);
          final hasEvents = eventDays.contains(day);
          final isToday = AppDate.isSameDay(day, today);
          final foreground = isSelected
              ? const Color(0xFF0A231C)
              : Colors.white;
          return InkWell(
            key: ValueKey('calendar-day-${day.year}-${day.month}-${day.day}'),
            onTap: () => onSelected(day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? EcoTraceColors.lemon
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppDate.weekday(day),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0A231C)
                          : const Color(0xFFA3B8AC),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? foreground
                          : (isToday
                                ? EcoTraceColors.lemon
                                : Colors.white),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: hasEvents
                          ? (isSelected
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




