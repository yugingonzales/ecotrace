import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Metrics and durations shared by every async-feedback primitive.
///
/// Screens pull their spinner sizes from here instead of hard-coding them, so
/// restyling loading feedback is a one-file change rather than a sweep.
abstract final class EcoLoading {
  /// Diameter of a spinner that replaces a button's label.
  static const double buttonSize = 20;

  static const double strokeWidth = 2.2;

  /// Diameter of a standalone / blocking spinner.
  static const double overlaySize = 34;

  static const Color onDark = Colors.white;

  static const Color onLight = EcoTraceColors.forest;

  /// Lower bound on how long a flash of feedback stays up. Without it a
  /// sub-frame operation shows nothing at all and the UI just looks dead.
  static const Duration minimumVisible = Duration(milliseconds: 400);
}

/// Spinner sized to sit inside a button, replacing its label while busy.
class EcoButtonLoader extends StatelessWidget {
  const EcoButtonLoader({
    super.key,
    this.color = EcoLoading.onDark,
    this.size = EcoLoading.buttonSize,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

/// Full-surface scrim that blocks input and reports a long-running process.
///
/// Sits above the screen content rather than replacing it, so the officer keeps
/// their context while a report or upload completes.
class EcoBlockingOverlay extends StatelessWidget {
  const EcoBlockingOverlay({
    super.key,
    required this.visible,
    this.message,
    this.scrimOpacity = 0.45,
  });

  final bool visible;

  /// What the system is doing, phrased as a present participle.
  final String? message;

  final double scrimOpacity;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: visible
        ? Stack(
            fit: StackFit.expand,
            children: [
              ModalBarrier(
                dismissible: false,
                color: Colors.black.withValues(alpha: scrimOpacity),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: EcoTraceColors.field,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: EcoLoading.overlaySize,
                        child: CircularProgressIndicator(
                          strokeWidth: EcoLoading.strokeWidth,
                          color: EcoLoading.onLight,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF0A231C),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          )
        : const Offstage(),
  );
}

/// Determinate progress bar with a percentage, for uploads whose size is known.
class EcoProgressBar extends StatelessWidget {
  const EcoProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.color = EcoTraceColors.forest,
  });

  /// Completion in the range 0..1. Values outside are clamped.
  final double progress;

  final String? label;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label ?? 'Uploading',
              style: const TextStyle(
                color: EcoTraceColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: const TextStyle(
                color: EcoTraceColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: EcoTraceColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Shimmering placeholder for content that has not arrived yet.
///
/// Animates a highlight sweep across inert blocks so a first load reads as
/// "loading" rather than as an empty screen.
class EcoSkeleton extends StatefulWidget {
  const EcoSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<EcoSkeleton> createState() => _EcoSkeletonState();
}

class _EcoSkeletonState extends State<EcoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Honour the OS "remove animations" setting: a looping shimmer is exactly
  /// the kind of motion that setting exists to suppress.
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyMotionPreference(MediaQuery.disableAnimationsOf(context));
  }

  void _applyMotionPreference(bool still) {
    _still = still;
    if (still) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(
      color: EcoTraceColors.border,
      borderRadius: BorderRadius.circular(widget.borderRadius),
    ),
    child: _still
        ? null
        : AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) => FractionallySizedBox(
              alignment: Alignment(-1.6 + (_sweep.value * 3.2), 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
  );
}

/// A stack of skeleton rows shaped like a list of records.
class EcoSkeletonList extends StatelessWidget {
  const EcoSkeletonList({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < rows; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const EcoSkeleton(width: 44, height: 44, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    EcoSkeleton(height: 13, width: 180),
                    SizedBox(height: 7),
                    EcoSkeleton(height: 11, width: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
