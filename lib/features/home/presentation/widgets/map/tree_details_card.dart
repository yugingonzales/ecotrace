import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/map_tree.dart';
import 'tree_photo_gallery.dart';

class TreeDetailsCard extends StatelessWidget {
  const TreeDetailsCard({
    super.key,
    required this.tree,
    required this.onClose,
    required this.onStartVerification,
    required this.onReportIncident,
    required this.onTrace,
    required this.isTracing,
    required this.hasRoute,
    required this.onClearRoute,
  });

  final MapTree tree;
  final VoidCallback onClose;
  final VoidCallback onStartVerification;
  final VoidCallback onReportIncident;
  final VoidCallback onTrace;
  final bool isTracing;
  final bool hasRoute;
  final VoidCallback onClearRoute;

  /// Share of the viewport this sheet may occupy.
  ///
  /// Raised from 0.45 to leave room for the 140px photo cover without forcing
  /// a scroll on a typical phone. Still well short of full screen.
  static const double maxHeightFraction = 0.52;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 18,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet handle: signals the card is a draggable bottom sheet while
          // costing a single 4px row.
          Center(
            child: Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: EcoTraceColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SELECTED TREE',
                      style: TextStyle(
                        color: Color(0xFF7A9185),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tree.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EcoTraceColors.forest,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tree.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tree.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tree.statusLabel,
                      style: TextStyle(
                        color: tree.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      color: EcoTraceColors.muted,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TreeChip(label: 'SPECIES', value: tree.species),
              _TreeChip(label: 'ZONE', value: tree.zone),
              _TreeChip(label: 'PLANTED', value: tree.datePlanted),
              _TreeChip(label: 'PLANTER', value: tree.planter),
              _TreeChip(label: 'COORDS', value: tree.coordinates),
            ],
          ),
          const SizedBox(height: 10),
          // Tapping the cover opens the full photo gallery for this tree.
          TreePhotoCover(
            tree: tree,
            onTap: () => showTreePhotoGallery(context, tree),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoTraceColors.lemon,
                foregroundColor: EcoTraceColors.forest,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Verification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isTracing ? null : onTrace,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // `FittedBox` around the icon+label row (rather than
                  // `OutlinedButton.icon`) so a 320dp-wide phone shrinks the
                  // label instead of overflowing the half-width button.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isTracing)
                          const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.route_outlined, size: 16),
                        const SizedBox(width: 6),
                        const Text('Start navigation'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReportIncident,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EcoTraceColors.forest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    side: const BorderSide(color: EcoTraceColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Report incident'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasRoute)
            Center(
              child: TextButton.icon(
                onPressed: onClearRoute,
                icon: const Icon(Icons.clear_rounded, size: 14),
                label: const Text(
                  'Clear route',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: EcoTraceColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Single-line `LABEL value` pill used instead of a full-size info card, so the
/// details sheet stays short on small phones.
class _TreeChip extends StatelessWidget {
  const _TreeChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: EcoTraceColors.canvas,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: Color(0xFF7A9185),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        // `Flexible` (not a fixed `ConstrainedBox`) so the value shrinks to whatever
        // room the `Wrap` offers and ellipsizes instead of overflowing the chip.
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EcoTraceColors.forest,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}
