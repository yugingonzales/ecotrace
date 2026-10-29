import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationStore {
  static String _keyFor(int userId) => 'ecotrace_local_notifications_$userId';
  static String _readIdsKeyFor(int userId) =>
      'ecotrace_read_notification_ids_$userId';

  static Future<List<Map<String, dynamic>>> read(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    final values =
        preferences.getStringList(_keyFor(userId)) ?? const <String>[];
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
    required int userId,
    String? eventName,
    String? eventId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final current = await read(userId);
    current.removeWhere((item) => item['id'] == id);
    final readIds =
        preferences.getStringList(_readIdsKeyFor(userId))?.toSet() ??
        <String>{};
    readIds.remove(id);
    await preferences.setStringList(_readIdsKeyFor(userId), readIds.toList());
    current.insert(0, {
      'id': id,
      'title': title,
      'body': body,
      'label': label,
      'alert_type': alertType,
      'eventName': eventName,
      'eventId': eventId,
      'published_at': DateTime.now().toUtc().toIso8601String(),
      'read': false,
    });
    await preferences.setStringList(
      _keyFor(userId),
      current.take(100).map(jsonEncode).toList(),
    );
  }

  static Future<Set<String>> readIds(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_readIdsKeyFor(userId)) ??
            const <String>[])
        .toSet();
  }

  static Future<void> markReadIds(int userId, Iterable<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final current = await readIds(userId);
    current.addAll(ids);
    await preferences.setStringList(_readIdsKeyFor(userId), current.toList());
  }

  static Future<void> markRead(int userId, Iterable<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final readIds = ids.toSet();
    final current = await read(userId);
    for (final item in current) {
      if (readIds.contains(item['id'])) item['read'] = true;
    }
    await preferences.setStringList(
      _keyFor(userId),
      current.map(jsonEncode).toList(),
    );
    await markReadIds(userId, readIds);
  }
}
