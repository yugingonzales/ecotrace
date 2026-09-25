import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/monitoring_event_progress.dart';
import 'progress_track.dart';

class MonitoringProgressOverview extends StatelessWidget {
  const MonitoringProgressOverview({super.key, required this.summary});

  final MonitoringProgressSummary summary;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _OverallProgress(summary: summary),
      const SizedBox(height: 16),
      _SummaryStrip(summary: summary),
    ],
  );
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.summary});

  final MonitoringProgressSummary summary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: EcoTraceColors.forestDeep,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: EcoTraceColors.leaf.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VERIFIED PROGRESS',
          style: TextStyle(
            color: EcoTraceColors.leaf,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${summary.progressPercent}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'trees verified',
                      style: TextStyle(
                        color: EcoTraceColors.leaf,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatCount(summary.verifiedTrees)} of ${_formatCount(summary.targetTrees)}',
                      style: const TextStyle(
                        color: Color(0xFFC7D8D0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProgressTrack(
          progressPercent: summary.progressPercent,
          semanticLabel: 'Overall active event verification progress',
          height: 8,
          backgroundColor: Colors.white12,
          valueColor: EcoTraceColors.lemon,
        ),
        const SizedBox(height: 10),
        const Text(
          'Preview totals from active monitoring events',
          style: TextStyle(
            color: Color(0xFF9EB8AC),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final MonitoringProgressSummary summary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: _SummaryMetric(
            value: summary.activeStaff,
            label: 'active staff',
          ),
        ),
        const SizedBox(
          width: 1,
          height: 34,
          child: ColoredBox(color: EcoTraceColors.border),
        ),
        Expanded(
          child: _SummaryMetric(
            value: summary.pendingReviews,
            label: 'pending',
          ),
        ),
        const SizedBox(
          width: 1,
          height: 34,
          child: ColoredBox(color: EcoTraceColors.border),
        ),
        Expanded(
          child: _SummaryMetric(
            value: summary.incidents,
            label: 'incidents',
            highlight: true,
          ),
        ),
      ],
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        _formatCount(value),
        style: TextStyle(
          color: highlight ? EcoTraceColors.error : EcoTraceColors.forest,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: EcoTraceColors.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
