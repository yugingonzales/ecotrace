import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/widgets/shared/section_title.dart';
import '../data/monitoring_progress_preview.dart';
import '../domain/monitoring_event_progress.dart';
import 'widgets/event_progress_card.dart';
import 'widgets/progress_overview.dart';

class MonitoringProgressScreen extends StatelessWidget {
  const MonitoringProgressScreen({super.key});

  static final MonitoringProgressSummary _summary =
      MonitoringProgressSummary.fromEvents(monitoringProgressPreview);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: EcoTraceColors.canvas,
    body: SafeArea(
      child: Column(
        children: [
          _ProgressHeader(activeEventCount: _summary.activeEventCount),
          Expanded(
            child: ListView(
              key: const Key('monitoring-progress-list'),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                MonitoringProgressOverview(summary: _summary),
                const SizedBox(height: 24),
                const SectionTitle('Active monitoring events'),
                for (final event in monitoringProgressPreview)
                  EventProgressCard(key: ValueKey(event.id), event: event),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.activeEventCount});

  final int activeEventCount;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: EcoTraceColors.forest,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, EcoTraceHeader.topPadding, 20, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back to events',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .1),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONITORING OVERVIEW',
                  style: TextStyle(
                    color: EcoTraceColors.leaf,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Field progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .16),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeEventCount active',
                  style: const TextStyle(
                    color: EcoTraceColors.leaf,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
