import 'package:flutter/material.dart';

class GpsMarker extends StatelessWidget {
  const GpsMarker({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: const Color(0xFF2563EB),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Color(0x662563EB), blurRadius: 12)],
    ),
  );
}
