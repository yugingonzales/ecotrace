import 'package:flutter/material.dart';

import '../../../../../core/date/app_date.dart';
import '../../../../../core/theme/app_theme.dart';

/// Month grid of scheduled field activities.
///
class FullCalendarSheet extends StatefulWidget {
  const FullCalendarSheet({
    super.key,
    required this.daysWithEvents,
    this.endDaysWithEvents = const [],
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<DateTime> daysWithEvents;
  final List<DateTime> endDaysWithEvents;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<FullCalendarSheet> createState() => _FullCalendarSheetState();
}

class _FullCalendarSheetState extends State<FullCalendarSheet> {
  late DateTime _visibleMonth = AppDate.firstOfMonth(widget.selectedDay);

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildWeekdayHeaders(),
                  const SizedBox(height: 12),
                  _buildCalendarGrid(),
                  const SizedBox(height: 20),
                  _buildLegend(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDate.monthYear(_visibleMonth).toUpperCase(),
                  style: const TextStyle(
                    color: EcoTraceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                SizedBox(height: 2),
                const Text(
                  'Field activities',
                  style: TextStyle(
                    color: Color(0xFF0A231C),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous month',
            style: IconButton.styleFrom(foregroundColor: EcoTraceColors.muted),
          ),
          IconButton(
            onPressed: () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next month',
            style: IconButton.styleFrom(foregroundColor: EcoTraceColors.muted),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(foregroundColor: EcoTraceColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    return Row(
      children: AppDate.weekdayNames
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    color: EcoTraceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          _legendItem(EcoTraceColors.forest, 'Start'),
          _legendItem(const Color(0xFFF59E0B), 'End date'),
          _legendItem(EcoTraceColors.lemon, 'Selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: EcoTraceColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _buildCalendarGrid() {
    final today = AppDate.dayOf(DateTime.now());
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final monthLength = AppDate.daysInMonth(year, month);
    // `weekday` is 1 (Mon) through 7 (Sun), matching the fixed Mon–Sun header,
    // so the number of leading blanks is the real offset of the 1st.
    final leadingBlanks = DateTime(year, month, 1).weekday - 1;
    final weeksNeeded = ((monthLength + leadingBlanks) / 7).ceil();
    final eventDays = widget.daysWithEvents.map(AppDate.dayOf).toSet();
    final endDays = widget.endDaysWithEvents.map(AppDate.dayOf).toSet();

    final List<Widget> weeks = [];
    var currentDay = 1;

    for (int week = 0; week < weeksNeeded; week++) {
      final List<Widget> days = [];

      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        if (week == 0 && dayOfWeek <= leadingBlanks) {
          days.add(const Expanded(child: SizedBox()));
        } else if (currentDay > monthLength) {
          days.add(const Expanded(child: SizedBox()));
        } else {
          final day = DateTime(year, month, currentDay);
          final hasEvents = eventDays.contains(day);
          final hasEnd = endDays.contains(day);
          final isSelected = AppDate.isSameDay(day, widget.selectedDay);
          final isToday = AppDate.isSameDay(day, today);
          final label = '$currentDay';
          currentDay++;

          days.add(
            Expanded(
              child: InkWell(
                onTap: () {
                  widget.onDaySelected(day);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EcoTraceColors.forest
                        : (isToday
                              ? EcoTraceColors.lemon.withValues(alpha: .2)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: EcoTraceColors.lemon, width: 1.5)
                        : null,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isToday
                                      ? EcoTraceColors.forest
                                      : const Color(0xFF0A231C)),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasEvents || hasEnd)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasEvents)
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? EcoTraceColors.lemon
                                        : EcoTraceColors.forest,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasEvents && hasEnd) const SizedBox(width: 3),
                              if (hasEnd)
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                            ],
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          currentDay++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: days),
        ),
      );
    }

    return Column(children: weeks);
  }
}
