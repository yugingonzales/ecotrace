import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class AuditRow extends StatelessWidget {
  const AuditRow({
    required this.date,
    required this.text,
    required this.staff,
    super.key,
  });

  final String date;
  final String text;
  final String staff;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.timeline_rounded,
          color: EcoTraceColors.forest,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF7A9185),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF0A231C),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                staff,
                style: const TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
