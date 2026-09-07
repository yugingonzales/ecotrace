import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../shared/surface_card.dart';

class EmptyEventsState extends StatelessWidget {
  const EmptyEventsState({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              color: EcoTraceColors.muted,
              size: 32,
            ),
            const SizedBox(height: 10),
            const Text(
              'No activities found',
              style: TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try another date, search term, or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: EcoTraceColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
}
