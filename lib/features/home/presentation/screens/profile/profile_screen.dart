import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/shared/info_row.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/surface_card.dart';
import '../../widgets/shared/top_bar.dart';
import '../sync/sync_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: EcoTraceColors.forest,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  TopBar(edgeOffset: 20),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .15),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: EcoTraceColors.lemon,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'MS',
                              style: TextStyle(
                                color: EcoTraceColors.forest,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monitoring Staff',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Field verifier',
                                style: TextStyle(
                                  color: Color(0xFFA3E635),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'STAFF-00042',
                                style: TextStyle(
                                  color: Color(0xFFE8F5ED),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              const SectionTitle('Account details'),
              SurfaceCard(
                child: Column(
                  children: [
                    const InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Staff number',
                      value: '239038',
                    ),
                    const InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Staff type',
                      value: 'Field staff',
                    ),
                    InfoRow(
                      icon: Icons.cloud_done_outlined,
                      label: 'Sync status',
                      value: 'All records synced',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SyncDashboardScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EcoTraceColors.error,
                  side: const BorderSide(
                    color: EcoTraceColors.border,
                    width: 2,
                  ),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
