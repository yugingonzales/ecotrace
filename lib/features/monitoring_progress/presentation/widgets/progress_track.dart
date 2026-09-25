import 'package:flutter/material.dart';

class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.progressPercent,
    required this.semanticLabel,
    this.backgroundColor = const Color(0xFFE1E8E3),
    this.valueColor = const Color(0xFF0D382C),
    this.height = 7,
  });

  final int progressPercent;
  final String semanticLabel;
  final Color backgroundColor;
  final Color valueColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final normalizedPercent = progressPercent.clamp(0, 100);
    return Semantics(
      container: true,
      label: semanticLabel,
      value: '$normalizedPercent%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: backgroundColor),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: normalizedPercent / 100,
                    heightFactor: 1,
                    child: ColoredBox(color: valueColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
