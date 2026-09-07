import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../painters/pin_tail_painter.dart';

class TreeMarker extends StatelessWidget {
  const TreeMarker({
    super.key,
    required this.code,
    required this.color,
    this.onTap,
  });

  final String code;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Semantics(
      button: true,
      label: 'Tree marker $code',
      child: Column(
        children: [
          SizedBox(
            width: 38,
            height: 42,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.park_outlined,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                Positioned(
                  top: 28,
                  child: CustomPaint(
                    size: const Size(10, 14),
                    painter: PinTailPainter(color),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: EcoTraceColors.forest,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 5),
              ],
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
