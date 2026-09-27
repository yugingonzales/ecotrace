import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../field_verification/domain/verification_draft.dart';

/// First stage of verification: choose how the plant is analysed.
///
/// The automatic option is present but inert. It is shown disabled rather than
/// hidden so the capability is visible in the product, and it is *not* wired
/// to a placeholder that invents measurements.
class AnalysisModeScreen extends StatelessWidget {
  const AnalysisModeScreen({
    super.key,
    required this.treeId,
    required this.species,
    required this.onManualChosen,
  });

  final String treeId;
  final String species;
  final ValueChanged<AnalysisMode> onManualChosen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EcoTraceColors.forest,
        foregroundColor: Colors.white,
        title: Text(
          'Verify $treeId',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              species,
              style: const TextStyle(
                color: EcoTraceColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How should this plant be analysed?',
              style: TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            _ModeCard(
              mode: AnalysisMode.manual,
              icon: Icons.edit_note_rounded,
              onTap: () => onManualChosen(AnalysisMode.manual),
            ),
            const SizedBox(height: 14),
            const _ModeCard(
              mode: AnalysisMode.automatic,
              icon: Icons.auto_awesome_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.icon, this.onTap});

  final AnalysisMode mode;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Opacity(
      opacity: available ? 1 : .55,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: available ? EcoTraceColors.forest : EcoTraceColors.border,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: available
                      ? EcoTraceColors.forest
                      : EcoTraceColors.border,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: available ? Colors.white : EcoTraceColors.muted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: available
                            ? const Color(0xFF0A231C)
                            : EcoTraceColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mode.blurb,
                      style: const TextStyle(
                        color: EcoTraceColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    if (!available) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: EcoTraceColors.lemon,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Color(0xFF0A231C),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (available)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: EcoTraceColors.forest,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
