import 'package:flutter/material.dart';

class GpsMarker extends StatefulWidget {
  const GpsMarker({super.key, this.heading = 0, this.animate = false});

  final double heading;
  final bool animate;

  @override
  State<GpsMarker> createState() => _GpsMarkerState();
}

class _GpsMarkerState extends State<GpsMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GpsMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _pulse.repeat(reverse: true);
    } else if (!widget.animate && oldWidget.animate) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (context, child) => SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 34 + (_pulse.value * 12),
            height: 34 + (_pulse.value * 12),
            decoration: BoxDecoration(
              color: const Color(0x332563EB)
                  .withValues(alpha: 0.12 + (_pulse.value * 0.12)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x882563EB)
                      .withValues(alpha: 0.22 + (_pulse.value * 0.22)),
                  blurRadius: 10 + (_pulse.value * 8),
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: widget.heading * 3.141592653589793 / 180,
            child: const Align(
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.navigation_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0xAA2563EB), blurRadius: 12),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
