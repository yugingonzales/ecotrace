import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationStore {
  static const _key = 'ecotrace_local_notifications';

  static Future<List<Map<String, dynamic>>> read() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_key) ?? const <String>[];
    return values
        .map((value) => jsonDecode(value))
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  static Future<void> add({
    required String id,
    required String title,
    required String body,
    required String label,
    required String alertType,
    String? eventName,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final current = await read();
    current.removeWhere((item) => item['id'] == id);
    current.insert(0, {
      'id': id,
      'title': title,
      'body': body,
      'label': label,
      'alert_type': alertType,
      'eventName': eventName,
      'published_at': DateTime.now().toUtc().toIso8601String(),
      'read': false,
    });
    await preferences.setStringList(
      _key,
      current.take(100).map(jsonEncode).toList(),
    );
  }

  static Future<void> markRead(Iterable<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final readIds = ids.toSet();
    final current = await read();
    for (final item in current) {
      if (readIds.contains(item['id'])) item['read'] = true;
    }
    await preferences.setStringList(_key, current.map(jsonEncode).toList());
  }
}
