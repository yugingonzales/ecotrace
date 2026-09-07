import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/shared/surface_card.dart';

class SyncRecord extends StatelessWidget {
  const SyncRecord({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.background,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0A231C),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
