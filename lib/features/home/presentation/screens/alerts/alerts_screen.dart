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
    this.onAction,
    this.isOpen = false,
  });

  final ValueChanged<int>? onUnreadCountChanged;
  final ValueChanged<AlertData>? onAction;
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
  int? _userId;

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
      final readIds = session == null
          ? <String>{}
          : await NotificationStore.readIds(session.user.id);
      if (!mounted) return;
      setState(() {
        _userId = session?.user.id;
        _readAlertIds
          ..clear()
          ..addAll(readIds);
        _localAlerts = localItems.map(AlertData.fromLocal).toList();
        _alerts = items
            .map((item) => AlertData.fromApi(item as Map<String, dynamic>))
            .toList();
        _loading = false;
        _failed = false;
      });
      widget.onUnreadCountChanged?.call(_unreadCount);
      if (widget.isOpen) await _markAllAsRead();
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
    final userId = _userId;
    if (userId != null) await NotificationStore.markRead(userId, ids);
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  /// Pull-to-refresh re-reads the published alert feed from the server.
  Future<void> _refresh() async {
    setState(() => _filter = AlertFilter.all);
    await _loadAlerts();
  }

  Future<void> _markAlertRead(String id) async {
    if (!mounted) return;
    setState(() => _readAlertIds.add(id));
    final userId = _userId;
    if (userId != null) await NotificationStore.markRead(userId, [id]);
    if (mounted) widget.onUnreadCountChanged?.call(_unreadCount);
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
    final liveAlert = allAlerts.cast<AlertData?>().firstWhere(
      (alert) => alert?.notificationCode == 'event_live',
      orElse: () => null,
    );
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
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
                if (liveAlert != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F5E3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${liveAlert.title}\nGeofencing and AR capture are open.',
                            style: const TextStyle(
                              color: Color(0xFF14532D),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    eventName: alert.eventName,
                    notificationCode: alert.notificationCode,
                    actionable: alert.isActionable && widget.onAction != null,
                    onViewed: () => _markAlertRead(alert.id),
                    onAction: alert.isActionable && widget.onAction != null
                        ? () {
                            _markAlertRead(alert.id);
                            widget.onAction!(alert);
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
