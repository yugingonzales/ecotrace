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

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DFD8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              event.title,
              style: const TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.time,
              style: const TextStyle(
                color: EcoTraceColors.forest,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: EcoTraceColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(
                      color: EcoTraceColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 17,
                  color: EcoTraceColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${event.attendeeCount} monitoring personnel joined',
                  style: const TextStyle(
                    color: EcoTraceColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              event.description,
              style: const TextStyle(
                color: EcoTraceColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onConfirm,
                icon: Icon(
                  joined
                      ? Icons.check_circle_outline
                      : Icons.event_available_outlined,
                ),
                label: Text(joined ? 'Joined' : 'Confirm participation'),
                style: FilledButton.styleFrom(
                  backgroundColor: joined
                      ? const Color(0xFFE8F0EC)
                      : EcoTraceColors.forest,
                  foregroundColor:
                      joined ? const Color(0xFF2D8A56) : Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      );
}
