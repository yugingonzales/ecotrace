import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../shared/surface_card.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    required this.title,
    required this.time,
    required this.label,
    required this.color,
    required this.textColor,
    required this.body,
    super.key,
  });

  final String title;
  final String time;
  final String label;
  final Color color;
  final Color textColor;
  final String body;

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
                title,
                style: const TextStyle(
                  color: Color(0xFF0A231C),
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFF7A9185),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: const Text(
            'View details  →',
            style: TextStyle(
              color: EcoTraceColors.forest,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
