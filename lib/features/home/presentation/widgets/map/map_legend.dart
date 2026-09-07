import 'package:flutter/material.dart';

import '../shared/legend.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12)],
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Legend(color: Color(0xFF22C55E), text: 'Healthy'),
        Legend(color: Color(0xFFF97316), text: 'At risk'),
        Legend(color: Color(0xFF64748B), text: 'Unknown'),
      ],
    ),
  );
}
