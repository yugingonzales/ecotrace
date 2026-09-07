import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/scanner/manual_entry_sheet.dart';
import '../../widgets/shared/status_badge.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTraceColors.forest,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close scanner',
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Scan tag',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const StatusBadge(label: 'GPS ready'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: EcoTraceColors.lemon, width: 3),
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.black.withValues(alpha: .2),
                    ),
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white38),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.center_focus_strong_rounded,
                          color: EcoTraceColors.lemon,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scan NFC or QR tag',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 240,
                    child: Text(
                      'Align the code inside the viewfinder. GPS location will be locked automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA3C2B5),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              child: FilledButton.icon(
                onPressed: () => _showManualEntry(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Enter tree details manually'),
                style: FilledButton.styleFrom(
                  backgroundColor: EcoTraceColors.lemon,
                  foregroundColor: const Color(0xFF0A231C),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showManualEntry(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EcoTraceColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const ManualEntrySheet(),
    );
  }
}
