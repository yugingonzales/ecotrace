import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/local_event.dart';

class EventDetailsSheet extends StatelessWidget {
  const EventDetailsSheet({
    super.key,
    required this.event,
    required this.joined,
    required this.onConfirm,
  });
  final LocalEvent event;
  final bool joined;
  final VoidCallback onConfirm;

  double get progress => event.targetTrees <= 0
      ? 0
      : (event.verifiedTrees / event.targetTrees).clamp(0, 1).toDouble();
  int get remaining =>
      (event.targetTrees - event.verifiedTrees).clamp(0, event.targetTrees);

  String get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (event.effectiveEndDate.isBefore(today)) return 'COMPLETED';
    if (!event.date.isAfter(today)) return 'ONGOING';
    return 'UPCOMING';
  }

  String get schedule {
    final start = '${event.date.day}/${event.date.month}/${event.date.year}';
    if (!event.spansMultipleDays) return '$start · ${event.time}';
    final end = event.effectiveEndDate;
    return '$start – ${end.day}/${end.month}/${end.year} · ${event.time}';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _Handle()),
          const SizedBox(height: 18),
          _Header(event: event, status: status, joined: joined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  Icons.flag_outlined,
                  '${event.targetTrees}',
                  'Your quota',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  Icons.task_alt_rounded,
                  '${event.verifiedTrees}',
                  'Completed',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  Icons.groups_outlined,
                  '${event.attendeeCount}',
                  'Active now',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressCard(sheet: this),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Activity details',
            children: [
              _DetailRow(Icons.calendar_today_outlined, 'Schedule', schedule),
              _DetailRow(
                Icons.location_on_outlined,
                'Field site',
                event.location,
              ),
              _DetailRow(
                Icons.groups_outlined,
                'Active participants',
                '${event.attendeeCount} monitoring personnel',
              ),
            ],
          ),
          if (event.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'About this activity',
              style: TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              event.description,
              style: const TextStyle(
                color: EcoTraceColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (event.monitoringMetrics.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Required monitoring details',
              style: TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: event.monitoringMetrics
                  .map((metric) => _Tag(metric))
                  .toList(),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: joined
                ? OutlinedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: const Text('Leave activity'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A4035),
                      side: const BorderSide(color: Color(0xFFE4B7AE)),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Join this activity'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EcoTraceColors.forest,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFD5DFD8),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.event,
    required this.status,
    required this.joined,
  });
  final LocalEvent event;
  final String status;
  final bool joined;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [EcoTraceColors.forest, Color(0xFF176A4E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge(status),
            const Spacer(),
            if (joined) const _Badge('JOINED'),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          event.location,
          style: const TextStyle(
            color: Color(0xFFD4F1DF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 12, 8, 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: EcoTraceColors.forest),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0A231C),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: EcoTraceColors.muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.sheet});
  final EventDetailsSheet sheet;
  @override
  Widget build(BuildContext context) => _InfoCard(
    title: sheet.joined ? 'Your activity progress' : 'Event progress',
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            sheet.event.targetTrees <= 0
                ? '—'
                : '${(sheet.progress * 100).round()}%',
            style: const TextStyle(
              color: EcoTraceColors.forest,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            sheet.event.targetTrees <= 0
                ? 'No quota assigned'
                : '${sheet.event.verifiedTrees} / ${sheet.event.targetTrees} completed',
            style: const TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: sheet.event.targetTrees <= 0 ? 0 : sheet.progress,
          minHeight: 9,
          backgroundColor: const Color(0xFFE6EEE9),
          valueColor: const AlwaysStoppedAnimation(EcoTraceColors.forest),
        ),
      ),
      const SizedBox(height: 9),
      Text(
        sheet.event.targetTrees <= 0
            ? 'Progress will appear once a quota is assigned.'
            : '${sheet.remaining} quota ${sheet.remaining == 1 ? 'item' : 'items'} remaining to complete.',
        style: const TextStyle(
          color: EcoTraceColors.muted,
          fontSize: 11,
          height: 1.35,
        ),
      ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0A231C),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: EcoTraceColors.forest),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(color: EcoTraceColors.muted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0A231C),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0EC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: EcoTraceColors.forest,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
