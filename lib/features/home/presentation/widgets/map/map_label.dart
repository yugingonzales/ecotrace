import 'package:flutter/material.dart';

class MapLabel extends StatelessWidget {
  const MapLabel({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xAA456B4A), size: 15),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xAA456B4A),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}
