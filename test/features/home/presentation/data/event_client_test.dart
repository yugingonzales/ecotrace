import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecotrace/features/home/presentation/data/event_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late http.BaseClient originalClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalClient = EventClient.httpClient;
  });

  tearDown(() {
    EventClient.httpClient = originalClient;
  });

  Map<String, dynamic> event({
    required int id,
    required String title,
    required String start,
    required String end,
  }) => {
    'event_id': id,
    'event_title': title,
    'event_description': 'Description',
    'event_location': 'UEP field site',
    'start_date': start,
    'end_date': end,
    'trees_per_student': 5,
    'attendee_count': 10,
    'monitoring_metrics': <String>['GPS Coordinates'],
    'event_boundary': <List<double>>[],
  };

  test(
    'all loads upcoming, ongoing, and past events without a status filter',
    () async {
      EventClient.httpClient = MockClient((request) async {
        expect(request.url.path, '/api/events');
        expect(request.url.query, isEmpty);
        return http.Response(
          jsonEncode({
            'items': [
              event(
                id: 1,
                title: 'Past',
                start: '2026-01-01',
                end: '2026-01-01',
              ),
              event(
                id: 2,
                title: 'Ongoing',
                start: '2026-10-01',
                end: '2026-12-01',
              ),
              event(
                id: 3,
                title: 'Upcoming',
                start: '2027-01-01',
                end: '2027-01-02',
              ),
            ],
          }),
          200,
        );
      });

      final events = await EventClient.all();

      expect(events.map((item) => item.title), ['Past', 'Ongoing', 'Upcoming']);
    },
  );

  test(
    'active refresh reflects edited data, deleted data, and date ranges',
    () async {
      final responses = <Map<String, dynamic>>[
        {
          'items': [
            event(
              id: 7,
              title: 'Original planting',
              start: '2026-11-01',
              end: '2026-11-01',
            ),
          ],
        },
        {
          'items': [
            event(
              id: 7,
              title: 'Edited planting',
              start: '2026-11-03',
              end: '2026-11-05',
            ),
          ],
        },
        {'items': const []},
      ];

      EventClient.httpClient = MockClient((request) async {
        expect(request.url.queryParameters['status'], 'active');
        return http.Response(jsonEncode(responses.removeAt(0)), 200);
      });

      final first = await EventClient.active();
      expect(first.single.title, 'Original planting');
      expect(first.single.spansMultipleDays, isFalse);

      final edited = await EventClient.active();
      expect(edited.single.title, 'Edited planting');
      expect(edited.single.date, DateTime(2026, 11, 3));
      expect(edited.single.effectiveEndDate, DateTime(2026, 11, 5));
      expect(edited.single.spansMultipleDays, isTrue);

      final deleted = await EventClient.active();
      expect(deleted, isEmpty);
    },
  );
}
