import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/data/auth_client.dart';
import '../../models/alert_data.dart';

class AnnouncementsSheet extends StatefulWidget {
  const AnnouncementsSheet({super.key});

  @override
  State<AnnouncementsSheet> createState() => _AnnouncementsSheetState();
}

class _AnnouncementsSheetState extends State<AnnouncementsSheet> {
  bool _loading = true;
  bool _failed = false;
  List<AlertData> _announcements = <AlertData>[];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final token = await AuthSession.token();
      final response = await http
          .get(
            Uri.parse(ApiConfig.alerts),
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw Exception('request failed');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>? ?? const <dynamic>[];
      final announcements = items
          .whereType<Map<String, dynamic>>()
          .map(AlertData.fromApi)
          .where(
            (alert) =>
                alert.label.toUpperCase() == 'ANNOUNCEMENT' ||
                alert.notificationCode == 'platform_announcement',
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5DFD8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: EcoTraceColors.lemon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: EcoTraceColors.forest,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANNOUNCEMENTS',
                      style: TextStyle(
                        color: EcoTraceColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Latest updates',
                      style: TextStyle(
                        color: EcoTraceColors.forestDeep,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_failed)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Unable to load announcements.')),
            )
          else if (_announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No announcements yet.')),
            )
          else
            ..._announcements.map(
              (announcement) => _AnnouncementCard(announcement: announcement),
            ),
        ],
      ),
    ),
  );
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final AlertData announcement;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FCF9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.campaign_outlined,
              color: EcoTraceColors.forest,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(
                  color: EcoTraceColors.forestDeep,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              announcement.time,
              style: const TextStyle(color: EcoTraceColors.muted, fontSize: 11),
            ),
          ],
        ),
        if (announcement.body.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            announcement.body,
            style: const TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
  );
}
