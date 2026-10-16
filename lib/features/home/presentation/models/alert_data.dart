import 'package:flutter/material.dart';

enum AlertFilter { all, recent, byDate }

class AlertData {
  const AlertData({
    required this.id,
    required this.title,
    required this.time,
    required this.label,
    required this.color,
    required this.textColor,
    required this.body,
    required this.filter,
    this.eventName,
    this.read = false,
  });

  final String id;

  final String title;
  final String time;
  final String label;
  final Color color;
  final Color textColor;
  final String body;
  final AlertFilter filter;
  final String? eventName;
  final bool read;

  factory AlertData.fromApi(Map<String, dynamic> json) {
    final type = json['alert_type'] as String? ?? 'info';
    final published =
        DateTime.tryParse(json['published_at'] as String? ?? '') ??
        DateTime.now();
    final recent = DateTime.now().difference(published).inDays < 7;
    final colors = switch (type) {
      'success' => (Color(0xFFD7F5E3), Color(0xFF15803D)),
      'warning' => (Color(0xFFFEF3C7), Color(0xFFD97706)),
      'error' => (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
      _ => (Color(0xFFE0F2FE), Color(0xFF0284C7)),
    };
    return AlertData(
      id: 'api-${json['alert_id']}',
      title: json['alert_title'] as String? ?? 'EcoTrace alert',
      time: _relativeTime(published),
      label: (json['alert_label'] as String? ?? 'INFO').toUpperCase(),
      color: colors.$1,
      textColor: colors.$2,
      body: json['alert_body'] as String? ?? '',
      filter: recent ? AlertFilter.recent : AlertFilter.byDate,
      eventName: json['event_title'] as String?,
    );
  }

  factory AlertData.fromLocal(Map<String, dynamic> json) {
    final published =
        DateTime.tryParse(json['published_at'] as String? ?? '') ??
        DateTime.now();
    final type = json['alert_type'] as String? ?? 'info';
    final colors = switch (type) {
      'success' => (Color(0xFFD7F5E3), Color(0xFF15803D)),
      'warning' => (Color(0xFFFEF3C7), Color(0xFFD97706)),
      'error' => (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
      _ => (Color(0xFFE0F2FE), Color(0xFF0284C7)),
    };
    return AlertData(
      id: json['id'] as String? ?? 'local-${published.toIso8601String()}',
      title: json['title'] as String? ?? 'EcoTrace notification',
      time: _relativeTime(published),
      label: (json['label'] as String? ?? 'INFO').toUpperCase(),
      color: colors.$1,
      textColor: colors.$2,
      body: json['body'] as String? ?? '',
      filter: DateTime.now().difference(published).inDays < 7
          ? AlertFilter.recent
          : AlertFilter.byDate,
      read: json['read'] as bool? ?? false,
      eventName: json['eventName'] as String?,
    );
  }

  static String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${value.month}/${value.day}/${value.year}';
  }
}
