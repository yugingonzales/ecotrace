import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/alerts/alert_card.dart';
import '../../widgets/alerts/filter_tabs.dart';
import '../../widgets/shared/top_bar.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: EcoTraceColors.forest,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBar(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: EcoTraceColors.lemon,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: EcoTraceColors.forest,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOOD MORNING!',
                            style: TextStyle(
                              color: EcoTraceColors.lemon,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Here\'s what\'s\nhappening today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: const [
                FilterTabs(),
                AlertCard(
                  title: 'Monitoring team selection',
                  time: 'Just now',
                  label: 'SELECTED',
                  color: Color(0xFFD7F5E3),
                  textColor: Color(0xFF15803D),
                  body: 'You have been selected for the Sector 4 Monitoring Team. Your expertise in tree health is a great addition to this mission.',
                ),
                AlertCard(
                  title: 'Mandatory tree survey',
                  time: '12 min ago',
                  label: 'URGENT',
                  color: Color(0xFFFEF3C7),
                  textColor: Color(0xFFD97706),
                  body: 'Complete the Sector 4 tree health monitoring by 17:00 today. High priority.',
                ),
                AlertCard(
                  title: 'Sync complete',
                  time: '2 hrs ago',
                  label: 'INFO',
                  color: Color(0xFFE0F2FE),
                  textColor: Color(0xFF0284C7),
                  body: '7 verification records have been successfully synchronized to the EcoTrace system.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
