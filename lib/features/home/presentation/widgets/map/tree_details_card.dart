import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/map_tree.dart';
import 'tree_info_card.dart';

class TreeDetailsCard extends StatelessWidget {
  const TreeDetailsCard({
    super.key,
    required this.tree,
    required this.onClose,
    required this.onStartVerification,
    required this.onReportIncident,
  });

  final MapTree tree;
  final VoidCallback onClose;
  final VoidCallback onStartVerification;
  final VoidCallback onReportIncident;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.7,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 24,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECTED TREE',
                      style: TextStyle(
                        color: Color(0xFF7A9185),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tree.id,
                      style: const TextStyle(
                        color: EcoTraceColors.forest,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: tree.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tree.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tree.statusLabel,
                      style: TextStyle(
                        color: tree.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.close_rounded,
                      color: EcoTraceColors.muted,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TreeInfoCard(label: 'COMMON NAME', value: tree.species),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TreeInfoCard(label: 'ZONE', value: tree.zone),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TreeInfoCard(
                  label: 'DATE PLANTED',
                  value: tree.datePlanted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TreeInfoCard(label: 'PLANTER', value: tree.planter),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TreeInfoCard(label: 'COORDINATES', value: tree.coordinates),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoTraceColors.lemon,
                foregroundColor: EcoTraceColors.forest,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReportIncident,
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('Report incident'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoTraceColors.forest,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: EcoTraceColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}