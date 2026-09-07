import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class FullCalendarSheet extends StatefulWidget {
  const FullCalendarSheet({
    super.key,
    required this.daysWithEvents,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<int> daysWithEvents;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  @override
  State<FullCalendarSheet> createState() => _FullCalendarSheetState();
}

class _FullCalendarSheetState extends State<FullCalendarSheet> {
  // September 2026 calendar data
  static const int daysInMonth = 30;
  static const int firstDayOfWeek = 1; // Monday (Sept 1, 2026 is Monday)

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEPTEMBER 2026',
                  style: TextStyle(
                    color: EcoTraceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              foregroundColor: EcoTraceColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    return Row(
      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
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
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: EcoTraceColors.lemon,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Days with scheduled activities',
            style: TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final List<Widget> weeks = [];
    int currentDay = 1;

    // Calculate total weeks needed
    final totalCells = daysInMonth + (firstDayOfWeek - 1);
    final weeksNeeded = (totalCells / 7).ceil();

    for (int week = 0; week < weeksNeeded; week++) {
      final List<Widget> days = [];

      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        if (week == 0 && dayOfWeek < firstDayOfWeek) {
          days.add(const Expanded(child: SizedBox()));
        } else if (currentDay > daysInMonth) {
          days.add(const Expanded(child: SizedBox()));
        } else {
          final day = currentDay;
          final hasEvents = widget.daysWithEvents.contains(day);
          final isSelected = day == widget.selectedDay;
          final isToday = day == 6;

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
                          '$day',
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
                        if (hasEvents)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EcoTraceColors.lemon
                                  : EcoTraceColors.forest,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 4),
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
