import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/shared/surface_card.dart';
import '../../domain/monitoring_event_progress.dart';
import 'progress_track.dart';

class EventProgressCard extends StatelessWidget {
  const EventProgressCard({super.key, required this.event});

  final MonitoringEventProgress event;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                event.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0A231C),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EcoTraceColors.leaf.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${event.progressPercent}%',
                style: const TextStyle(
                  color: EcoTraceColors.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          event.dateRange,
          style: const TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: EcoTraceColors.muted,
              size: 14,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                event.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_formatCount(event.safeVerifiedTrees)} / ${_formatCount(event.safeTargetTrees)} trees',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EcoTraceColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressTrack(
          progressPercent: event.progressPercent,
          semanticLabel: '${event.name} verification progress',
          backgroundColor: EcoTraceColors.canvas,
          valueColor: EcoTraceColors.leafDeep,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _EventMetric(
                icon: Icons.groups_2_outlined,
                value: event.staffCount,
                label: 'staff',
              ),
            ),
            Expanded(
              child: _EventMetric(
                icon: Icons.hourglass_top_rounded,
                value: event.pendingReviewCount,
                label: 'pending',
              ),
            ),
            Expanded(
              child: _EventMetric(
                icon: Icons.report_problem_outlined,
                value: event.incidentCount,
                label: 'incidents',
                highlight: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EventMetric extends StatelessWidget {
  const _EventMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 15,
        color: highlight ? EcoTraceColors.error : EcoTraceColors.muted,
      ),
      const SizedBox(height: 4),
      Text(
        _formatCount(value),
        style: TextStyle(
          color: highlight ? EcoTraceColors.error : EcoTraceColors.forest,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: EcoTraceColors.muted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
