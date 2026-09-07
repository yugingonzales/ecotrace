import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/surface_card.dart';
import '../../widgets/sync/audit_row.dart';
import '../../widgets/sync/sync_record.dart';

class SyncDashboardScreen extends StatelessWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTraceColors.canvas,
      appBar: AppBar(
        backgroundColor: EcoTraceColors.forest,
        foregroundColor: Colors.white,
        title: const Text(
          'Sync dashboard',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sync status refreshed.'),
                backgroundColor: EcoTraceColors.forest,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh sync status',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7F5E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_done_outlined,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All records synced',
                        style: TextStyle(
                          color: Color(0xFF0A231C),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Last sync: Today, 09:42 AM',
                        style: TextStyle(
                          color: EcoTraceColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Verification feedback'),
          const SyncRecord(
            icon: Icons.check_circle_outline,
            title: 'T-104 verification',
            detail: 'Server accepted · 2 minutes ago',
            color: Color(0xFF15803D),
            background: Color(0xFFD7F5E3),
          ),
          const SyncRecord(
            icon: Icons.sync_rounded,
            title: 'T-109 verification',
            detail: 'Queued for upload · offline draft',
            color: Color(0xFFD97706),
            background: Color(0xFFFEF3C7),
          ),
          const SyncRecord(
            icon: Icons.history_rounded,
            title: 'T-097 audit feedback',
            detail: 'Reviewed by audit team · yesterday',
            color: Color(0xFF0284C7),
            background: Color(0xFFE0F2FE),
          ),
          const SectionTitle('Audit history'),
          const SurfaceCard(
            child: Column(
              children: [
                AuditRow(
                  date: 'Sep 6 · 09:40',
                  text: 'DBH measurement submitted',
                  staff: 'Monitoring staff · T-104',
                ),
                AuditRow(
                  date: 'Sep 5 · 16:12',
                  text: 'Plant status updated',
                  staff: 'Audit review · T-097',
                ),
                AuditRow(
                  date: 'Sep 4 · 11:28',
                  text: 'Incident report resolved',
                  staff: 'Field staff · T-088',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
