import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/data/auth_client.dart';
import '../models/local_event.dart';

class _DefaultEventHttpClient extends http.BaseClient {
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request);

  @override
  void close() => _client.close();
}

class EventClient {
  static const _cacheKey = 'ecotrace.joined_events';

  /// Replaced by tests with a deterministic client. Production uses the
  /// package client and keeps the same request behavior.
  static http.BaseClient httpClient = _DefaultEventHttpClient();

  static Future<List<LocalEvent>> active() => _load(ApiConfig.events);

  /// Loads the complete event catalogue so the Events tab can show upcoming,
  /// ongoing, and historical activities together.
  static Future<List<LocalEvent>> all() => _load(ApiConfig.allEvents);

  static Future<List<LocalEvent>> _load(String endpoint) async {
    final token = await AuthSession.token();
    final response = await httpClient
        .get(
          Uri.parse(endpoint),
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const EventClientException('Unable to load events.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => LocalEvent.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<LocalEvent>> joined() async {
    final token = await AuthSession.token();
    if (token == null) return cachedJoined();
    final response = await httpClient
        .get(Uri.parse(ApiConfig.joinedEvents), headers: _headers(token))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const EventClientException('Unable to load joined events.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final events = (body['items'] as List<dynamic>? ?? const [])
        .map((item) => LocalEvent.fromApi(item as Map<String, dynamic>))
        .toList();
    await _save(events);
    return events;
  }

  static Future<void> join(LocalEvent event) async {
    final token = await AuthSession.token();
    if (token == null) {
      throw const EventClientException('Sign in again to join this event.');
    }
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/events/${_numericId(event.id)}/join'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw const EventClientException(
        'Unable to join this event. Please try again.',
      );
    }
    final current = await cachedJoined();
    if (!current.any((item) => item.id == event.id)) {
      await _save([...current, event]);
    }
  }

  static Future<void> leave(LocalEvent event) async {
    final token = await AuthSession.token();
    if (token == null) {
      throw const EventClientException(
        'Sign in again to manage participation.',
      );
    }
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/events/${_numericId(event.id)}/join'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const EventClientException(
        'Unable to leave this event. Please try again.',
      );
    }
    final current = await cachedJoined();
    await _save(current.where((item) => item.id != event.id).toList());
  }

  static Future<List<LocalEvent>> cachedJoined() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_cacheKey) ?? const <String>[])
        .map(
          (item) =>
              LocalEvent.fromApi(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> _save(List<LocalEvent> events) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _cacheKey,
      events.map(_toApi).map(jsonEncode).toList(),
    );
  }

  static Map<String, dynamic> _toApi(LocalEvent event) => {
    'event_id': _numericId(event.id),
    'event_title': event.title,
    'event_description': event.description,
    'event_location': event.location,
    'start_date': _date(event.date),
    'end_date': _date(event.effectiveEndDate),
    'trees_per_student': event.targetTrees,
    'attendee_count': event.attendeeCount,
    'verified_trees': event.verifiedTrees,
    'monitoring_metrics': event.monitoringMetrics,
    'event_boundary': event.boundary,
  };

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String _numericId(String id) =>
      id.startsWith('api-') ? id.substring(4) : id;
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

class EventClientException implements Exception {
  const EventClientException(this.message);
  final String message;
  @override
  String toString() => message;
}
