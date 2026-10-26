import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../auth/data/auth_client.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/notification_store.dart';
import '../../models/alert_data.dart';
import '../../widgets/alerts/alert_card.dart';
import '../../widgets/alerts/filter_tabs.dart';
import '../../widgets/shared/top_bar.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    this.onUnreadCountChanged,
    this.isOpen = false,
  });

  final ValueChanged<int>? onUnreadCountChanged;
  final bool isOpen;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertFilter _filter = AlertFilter.all;
  List<AlertData> _alerts = <AlertData>[];
  bool _loading = true;
  bool _failed = false;
  final Set<String> _readAlertIds = <String>{};
  List<AlertData> _localAlerts = <AlertData>[];

  Future<void> _loadAlerts() async {
    try {
      final token = await AuthSession.token();
      final response = await http
          .get(
            Uri.parse(ApiConfig.alerts),
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw Exception('alert request failed');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>? ?? const <dynamic>[];
      final session = await AuthSession.restore();
      final localItems = session == null
          ? <Map<String, dynamic>>[]
          : await NotificationStore.read(session.user.id);
      if (!mounted) return;
      setState(() {
        _localAlerts = localItems.map(AlertData.fromLocal).toList();
        _alerts = items
            .map((item) => AlertData.fromApi(item as Map<String, dynamic>))
            .toList();
        _loading = false;
        _failed = false;
      });
      widget.onUnreadCountChanged?.call(_unreadCount);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void didUpdateWidget(AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOpen && widget.isOpen) _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final ids = [..._localAlerts, ..._alerts].map((alert) => alert.id).toSet();
    if (ids.isEmpty) return;
    setState(() => _readAlertIds.addAll(ids));
    // Server read state is authoritative; local state is updated in memory.
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  /// Pull-to-refresh re-reads the published alert feed from the server.
  Future<void> _refresh() async {
    setState(() => _filter = AlertFilter.all);
    await _loadAlerts();
  }

  int get _unreadCount {
    final seen = <String>{};
    return [..._localAlerts, ..._alerts]
        .where((alert) => seen.add(alert.id))
        .where((alert) => !alert.read && !_readAlertIds.contains(alert.id))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final allAlerts = [..._localAlerts, ..._alerts];
    final visibleAlerts = _filter == AlertFilter.all
        ? allAlerts
        : allAlerts.where((alert) => alert.filter == _filter).toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: EcoTraceHeader.decoration,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                EcoTraceHeader.topPadding,
                20,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TopBar(
                    edgeOffset: 20,
                    showSearch: false,
                    showFilter: false,
                  ),
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
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: EcoTraceColors.forest,
            child: ListView(
              key: const Key('alerts-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_failed)
                  const Text(
                    'Unable to load alerts. Pull to retry.',
                    textAlign: TextAlign.center,
                  ),
                FilterTabs(
                  selected: _filter,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
                for (final alert in visibleAlerts)
                  AlertCard(
                    title: alert.title,
                    time: alert.time,
                    label: alert.label,
                    color: alert.color,
                    textColor: alert.textColor,
                    body: alert.body,
                    onViewed: () {
                      setState(() => _readAlertIds.add(alert.id));
                      // Read state is persisted by the authenticated API.
                      widget.onUnreadCountChanged?.call(_unreadCount);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
