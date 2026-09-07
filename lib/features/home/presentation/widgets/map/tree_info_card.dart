import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class TreeInfoCard extends StatelessWidget {
  const TreeInfoCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7F5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A9185),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: EcoTraceColors.forest,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}
