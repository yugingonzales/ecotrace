import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    margin: const EdgeInsets.only(right: 2),
    decoration: BoxDecoration(
      color: EcoTraceColors.forest,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Center(
      child: Text(
          initials,
          style: const TextStyle(
            color: EcoTraceColors.lemon,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
    ),
  );
}
