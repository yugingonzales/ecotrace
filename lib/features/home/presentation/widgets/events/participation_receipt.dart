import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/date/app_date.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/local_event.dart';

/// How long the floating participation receipt stays on screen before it
/// clears itself. Exposed so tests can advance past it deterministically.
const kParticipationReceiptDuration = Duration(seconds: 3);

/// Shows the participation receipt as a floating pass above the current screen.

/// [useRootNavigator] defaults to `true` so the receipt floats above the app
/// shell's bottom navigation rather than being clipped to the body.
Future<void> showParticipationReceipt(
  BuildContext context,
  LocalEvent event, {
  bool useRootNavigator = true,
  bool leaving = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: 'Participation receipt',
    barrierColor: const Color(0x660A231C),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _ParticipationReceiptRoute(event: event, leaving: leaving),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: .92, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
}

class _ParticipationReceiptRoute extends StatefulWidget {
  const _ParticipationReceiptRoute({
    required this.event,
    required this.leaving,
  });

  final LocalEvent event;
  final bool leaving;

  @override
  State<_ParticipationReceiptRoute> createState() =>
      _ParticipationReceiptRouteState();
}

class _ParticipationReceiptRouteState extends State<_ParticipationReceiptRoute>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: kParticipationReceiptDuration,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _countdown.forward();
    _timer = Timer(kParticipationReceiptDuration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ParticipationReceiptCard(
            event: widget.event,
            remaining: _countdown,
            leaving: widget.leaving,
          ),
        ),
      ),
    ),
  );
}

/// The confirmation pass itself, with no overlay or dismissal logic.
class ParticipationReceiptCard extends StatelessWidget {
  const ParticipationReceiptCard({
    super.key,
    required this.event,
    this.remaining,
    this.leaving = false,
  });

  final LocalEvent event;
  final bool leaving;

  /// Counts from 0 to 1 over the receipt's lifetime and drains the bar at the
  /// foot of the pass. When null the countdown bar is omitted.
  final Animation<double>? remaining;

  @override
  Widget build(BuildContext context) {
    // The user themselves are now part of the attending group.
    final attending = leaving ? event.attendeeCount : event.attendeeCount + 1;

    return Semantics(
      container: true,
      liveRegion: true,
      label: leaving
          ? 'Activity left: ${event.title}'
          : 'Participation confirmed for ${event.title}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: EcoTraceColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0A231C),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Color(0xFF0A231C),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TimePill(
                    label:
                        '${AppDate.scheduleHeading(event.date)} · ${event.time}',
                  ),
                  _ReceiptRow(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                  _ReceiptRow(
                    icon: Icons.groups_outlined,
                    text: '$attending monitoring personnel',
                  ),
                ],
              ),
            ),
            _buildCountdownBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF167A58), Color(0xFF05291D)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -6,
          bottom: -18,
          child: Icon(
            Icons.eco_rounded,
            size: 96,
            color: Colors.white.withValues(alpha: .08),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: EcoTraceColors.lemon,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF0A231C),
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    leaving ? 'ACTIVITY LEFT' : 'PARTICIPATION CONFIRMED',
                    style: const TextStyle(
                      color: EcoTraceColors.lemon,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leaving ? 'You\'ve left' : 'You\'re in!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your place on the team is saved.',
                    style: TextStyle(
                      color: Color(0xFFD4E9DE),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'READY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildCountdownBar() {
    final remaining = this.remaining;
    if (remaining == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: remaining,
      builder: (context, _) => SizedBox(
        height: 3,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE1E8E3))),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (1 - remaining.value).clamp(0.0, 1.0),
                child: const ColoredBox(color: EcoTraceColors.lemon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF0A231C)),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EcoTraceColors.lemon,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: EcoTraceColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
