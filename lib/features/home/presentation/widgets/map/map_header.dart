import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class MapHeader extends StatelessWidget {
  const MapHeader({super.key, this.onTreeSelected});

  final void Function(String)? onTreeSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: EcoTraceColors.forest.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18)],
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: EcoTraceColors.lemon,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.layers_outlined,
            color: EcoTraceColors.forest,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'EcoTrace',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const Icon(Icons.circle, size: 7, color: Color(0xFFA3E635)),
        const SizedBox(width: 4),
        const Text(
          'Online',
          style: TextStyle(
            color: Color(0xFFA3E635),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
