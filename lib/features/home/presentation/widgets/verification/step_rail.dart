import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Horizontal progress rail for the verification wizard.

/// Shows every stage at once, including the ones not yet reachable, so the
/// officer can see the shape of the whole task before starting it.
class StepRail extends StatelessWidget {
  const StepRail({super.key, required this.labels, required this.currentIndex});

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: index <= currentIndex
                    ? EcoTraceColors.forest
                    : EcoTraceColors.border,
              ),
            ),
          _StepDot(
            index: index,
            label: labels[index],
            isCurrent: index == currentIndex,
            isDone: index < currentIndex,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isCurrent,
    required this.isDone,
  });

  final int index;
  final String label;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent || isDone
        ? EcoTraceColors.forest
        : EcoTraceColors.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrent || isDone
                ? EcoTraceColors.forest
                : EcoTraceColors.border,
            shape: BoxShape.circle,
          ),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 62,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
