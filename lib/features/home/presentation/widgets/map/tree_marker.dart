import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../painters/pin_tail_painter.dart';

class TreeMarker extends StatelessWidget {
  const TreeMarker({
    super.key,
    required this.code,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  final String code;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  /// Each marker paints onto its own raster layer (via [RepaintBoundary]) so
  /// the compositor simply translates cached marker paintings during camera
  /// pans instead of re-drawing all shadows + labels every frame.
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Tree marker $code',
        child: Column(
          children: [
            SizedBox(
              width: 44,
              height: 46,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (selected)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 6),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
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
                color: selected ? color : EcoTraceColors.forest,
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
    ),
  );
}
