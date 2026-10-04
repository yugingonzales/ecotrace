import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/event_quota.dart';
import '../../models/field_event_seed.dart';
import '../../models/local_event.dart';
import '../../widgets/events/leave_confirmation_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.joinedEventIds,
    required this.onLeave,
    required this.onMap,
  });
  final Set<String> joinedEventIds;
  final ValueChanged<LocalEvent> onLeave;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final events = buildFieldEventSeed()
        .where((e) => joinedEventIds.contains(e.id))
        .toList();
    final now = DateTime.now();
    final active = events.where(
      (e) =>
          !e.date.isAfter(now) &&
          e.effectiveEndDate.add(const Duration(days: 1)).isAfter(now),
    );
    final verified = events.fold(0, (sum, e) => sum + e.verifiedTrees);
    final pending = active.fold(0, (sum, e) => sum + _quota(e).remainingTrees);
    final eventTarget = events.fold(0, (sum, e) => sum + e.targetTrees);
    final eventParticipants = events.fold(
      0,
      (sum, e) => sum + e.attendeeCount + 1,
    );
    final eventProgress = eventTarget == 0
        ? 0.0
        : (verified / eventTarget).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A3D2E),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: EcoTraceColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: EcoTraceColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                  children: [
                    const Text(
                      'FIELD ACTIVITY',
                      style: TextStyle(
                        color: EcoTraceColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your activity',
                      style: TextStyle(
                        color: EcoTraceColors.forestDeep,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your impact and keep your field work moving.',
                      style: TextStyle(
                        color: EcoTraceColors.muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _UserProgressCard(verified: verified, pending: pending),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: onMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Verify more trees'),
                        style: FilledButton.styleFrom(
                          backgroundColor: EcoTraceColors.forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EventProgressCard(
                      target: eventTarget,
                      verified: verified,
                      participants: eventParticipants,
                      progress: eventProgress,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Joined events',
                            style: TextStyle(
                              color: EcoTraceColors.forestDeep,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _CountPill(count: events.length),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (events.isEmpty)
                      const _EmptyState()
                    else
                      ...events.map(
                        (e) => _EventCard(
                          event: e,
                          onLeave: () => _confirmLeave(context, e),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, LocalEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x990A231C),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: LeaveConfirmationCard(
          event: event,
          onCancel: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
        ),
      ),
    );
    if (confirmed == true) onLeave(event);
  }

  static EventQuota _quota(LocalEvent e) => EventQuota(
    targetTrees: e.targetTrees,
    participantCount: e.attendeeCount + 1,
    verifiedTrees: e.verifiedTrees,
    previousParticipantCount: e.attendeeCount,
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF0A3D2E), Color(0xFF124E3F)]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: EcoTraceColors.lemon,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.eco, size: 20, color: EcoTraceColors.forest),
        ),
        const SizedBox(width: 10),
        const Text(
          'EcoTrace',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _UserProgressCard extends StatelessWidget {
  const _UserProgressCard({required this.verified, required this.pending});
  final int verified;
  final int pending;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionLabel(icon: Icons.person_outline, text: 'YOUR PROGRESS'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _Metric(
              value: pending,
              label: 'Remaining quota',
              icon: Icons.pending_actions_outlined,
              accent: EcoTraceColors.lemon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Metric(
              value: verified,
              label: 'Verified trees',
              icon: Icons.verified_outlined,
              accent: EcoTraceColors.leafDeep,
            ),
          ),
        ],
      ),
    ],
  );
}

class _EventProgressCard extends StatelessWidget {
  const _EventProgressCard({
    required this.target,
    required this.verified,
    required this.participants,
    required this.progress,
  });
  final int target;
  final int verified;
  final int participants;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF185341),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x220A3D2E),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.public,
          text: 'OVERALL EVENT PROGRESS',
          light: true,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$verified / $target trees verified',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: EcoTraceColors.lemon,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white24,
            color: EcoTraceColors.lemon,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 18,
              color: Color(0xFFB8D8C8),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '$participants active participants',
                style: const TextStyle(
                  color: Color(0xFFB8D8C8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '$target target trees',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
    this.light = false,
  });
  final IconData icon;
  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: light ? EcoTraceColors.lemon : EcoTraceColors.forest,
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: light ? const Color(0xFFB8D8C8) : EcoTraceColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });
  final int value;
  final String label;
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.fromLTRB(12, 13, 10, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: EcoTraceColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F382C),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accent),
        const SizedBox(height: 22),
        Text(
          '$value',
          style: const TextStyle(
            color: EcoTraceColors.forestDeep,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 10,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F7E8),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count ${count == 1 ? 'event' : 'events'}',
      style: const TextStyle(
        color: EcoTraceColors.forest,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onLeave});
  final LocalEvent event;
  final VoidCallback onLeave;
  @override
  Widget build(BuildContext context) {
    final q = DashboardScreen._quota(event);
    final progress = q.assignedTrees == 0
        ? 0.0
        : q.safeVerifiedTrees / q.assignedTrees;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoTraceColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F382C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: EcoTraceColors.forestDeep,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onLeave,
                tooltip: 'Leave event',
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: EcoTraceColors.muted,
                ),
              ),
            ],
          ),
          Text(
            '${event.targetTrees} target trees � ${event.attendeeCount + 1} participants',
            style: const TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: EcoTraceColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your quota',
                style: TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${q.assignedTrees} trees',
                style: const TextStyle(
                  color: EcoTraceColors.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${q.safeVerifiedTrees} / ${q.assignedTrees} verified',
            style: const TextStyle(
              color: EcoTraceColors.forestDeep,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Color(0xFFE5ECE7),
              color: EcoTraceColors.leafDeep,
            ),
          ),
          if (q.quotaDropped)
            Container(
              margin: const EdgeInsets.only(top: 13),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'Quota updated as participants joined � now ${q.assignedTrees}',
                style: const TextStyle(
                  color: Color(0xFF856404),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 42,
          color: EcoTraceColors.forest,
        ),
        SizedBox(height: 12),
        Text(
          'No joined activities yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
