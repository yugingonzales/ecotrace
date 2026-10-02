// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecotrace/main.dart';
import 'package:ecotrace/features/home/presentation/app_shell.dart';
import 'package:ecotrace/core/connectivity/app_connectivity_scope.dart';
import 'package:ecotrace/core/connectivity/connection_status.dart';
import 'package:ecotrace/core/connectivity/connectivity_banner_host.dart';
import 'package:ecotrace/core/connectivity/connectivity_controller.dart';
import 'package:ecotrace/core/connectivity/internet_probe.dart';
import 'package:ecotrace/core/theme/app_theme.dart';
import 'package:ecotrace/features/home/presentation/widgets/events/participation_receipt.dart';
import 'package:ecotrace/features/home/presentation/models/local_event.dart';
import 'package:ecotrace/features/home/presentation/widgets/events/calendar_strip.dart';
import 'package:ecotrace/core/date/app_date.dart';
import 'package:ecotrace/features/field_verification/domain/verification_proximity.dart';
import 'package:ecotrace/features/home/presentation/screens/alerts/alerts_screen.dart';
import 'package:ecotrace/features/home/presentation/screens/events/events_screen.dart';
import 'package:ecotrace/features/home/presentation/screens/map/map_screen.dart';
import 'package:ecotrace/features/home/presentation/screens/profile/profile_screen.dart';
import 'package:ecotrace/features/auth/presentation/staff_auth_screen.dart';
import 'package:ecotrace/features/home/presentation/widgets/map/map_header.dart';
import 'package:ecotrace/features/home/presentation/widgets/shared/top_bar.dart';
import 'package:ecotrace/features/monitoring_progress/presentation/monitoring_progress_screen.dart';

void main() {
  testWidgets('every tab header, including the map, lines up with the rest', (
    WidgetTester tester,
  ) async {
    // The map header was the one that got missed: it is a floating pill with no
    // SafeArea, pinned by a Positioned, so it was never on the shared constant
    // and the earlier fix silently skipped it. These cases assert on real
    // screen position rather than on a padding value, because a wrong top is
    // exactly what a padding-only assertion cannot see.
    for (final inset in <double>[24, 28, 40]) {
      // MaterialApp supplies Directionality and the Material ancestors these
      // screens need; MediaQuery sits *inside* it so the explicit padding wins
      // over the one MaterialApp derives from the (zero-sized) test view.
      Widget withInset(Widget child) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: inset)),
          child: Scaffold(body: child),
        ),
      );

      await tester.pumpWidget(withInset(const AlertsScreen()));
      await tester.pumpAndSettle();
      final tabTop = tester.getTopLeft(find.byType(TopBar)).dy;

      await tester.pumpWidget(withInset(const MapScreen()));
      await tester.pumpAndSettle();
      final mapTop = tester.getTopLeft(find.byType(MapHeader)).dy;

      expect(
        mapTop,
        tabTop,
        reason:
            'map header must sit at the same y as the tab headers '
            '(inset $inset, shared gap ${EcoTraceHeader.topPadding})',
      );
      // Both are derived from the shared constant, so pin the relationship to
      // an absolute too: the map cannot be "aligned" by coincidence.
      expect(mapTop, inset + EcoTraceHeader.topPadding);
    }
  });

  testWidgets('the four tab headers share one top gap', (
    WidgetTester tester,
  ) async {
    // Each header used to hard-code its own value and they had already drifted
    // apart (16 on three screens, 12 on the dashboard), which is how a set of
    // headers ends up visually misaligned.
    Future<double> headerTopPadding(Widget screen, Finder firstRow) async {
      // The Scaffold is supplied here because these screens are built to sit
      // inside AppShell's IndexedStack; on their own they have no Material
      // ancestor and the TopBar's buttons fail to build.
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
      await tester.pumpAndSettle();

      // The header's own wrapper, not some inner Padding: find.ancestor walks
      // the whole chain, and the title rows and text blocks have their own.
      // `.first` is the nearest one, which is the header's padding.
      final padding = find
          .ancestor(of: firstRow, matching: find.byType(Padding))
          .first;
      expect(padding, findsOneWidget);
      return tester
          .widget<Padding>(padding)
          .padding
          .resolve(TextDirection.ltr)
          .top;
    }

    // The three tab headers all open with the shared TopBar; the dashboard
    // opens with a back button instead.
    final tops = <double>[
      await headerTopPadding(const EventsScreen(), find.byType(TopBar)),
      await headerTopPadding(const AlertsScreen(), find.byType(TopBar)),
      await headerTopPadding(const ProfileScreen(), find.byType(TopBar)),
      await headerTopPadding(
        const MonitoringProgressScreen(),
        find.byTooltip('Back to events'),
      ),
    ];

    // One value for all four, and it must be the compact one. The bound is
    // deliberately tight: the original complaint was "too much empty space",
    // and an assertion like `lessThan(16)` would have passed against the very
    // layout that caused it.
    for (final top in tops) {
      expect(top, EcoTraceHeader.topPadding);
      expect(top, lessThanOrEqualTo(4));
    }

    // And the gap really is just the constant, not the constant plus a second
    // hidden inset. `SafeArea` is the only other contributor, so with no
    // status bar in a test window the row must sit exactly at the padding.
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const AlertsScreen())),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(TopBar)).dy,
      EcoTraceHeader.topPadding,
    );
  });

  testWidgets('launches directly into the main application shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoTraceApp());

    expect(find.text("Today's schedule"), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('navigates between the reference frontend surfaces', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    expect(find.text('Today\'s schedule'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('UEP Catarman · Streets'), findsOneWidget);
    expect(find.text('TRE-0892'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pump();
    expect(find.text('GOOD MORNING!'), findsOneWidget);
  });

  testWidgets('filters alerts through the shared alert tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AlertsScreen())),
    );

    expect(find.text('Monitoring team selection'), findsOneWidget);
    expect(find.text('Mandatory tree survey'), findsOneWidget);
    await tester.tap(find.text('By date'));
    await tester.pump();

    expect(find.text('Mandatory tree survey'), findsOneWidget);
    expect(find.text('Monitoring team selection'), findsNothing);
  });

  testWidgets('edits profile contact fields and saves them', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );

    expect(find.text('monitoring.staff@ecotrace.local'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'field.team@ecotrace.local');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('field.team@ecotrace.local'), findsOneWidget);
  });

  testWidgets('opens field progress from the center action and stays usable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    expect(find.byTooltip('View field progress'), findsOneWidget);

    await tester.tap(find.byTooltip('View field progress'));
    await tester.pumpAndSettle();
    expect(find.text('Field progress'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(find.text('2,195 of 4,000'), findsOneWidget);
    expect(find.text('Arbor Day Drive 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Back to events'));
    await tester.pumpAndSettle();
    expect(find.text('Today\'s schedule'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.tap(find.text('All records synced'));
    await tester.pumpAndSettle();
    expect(find.text('Sync dashboard'), findsOneWidget);
  });

  testWidgets('keeps field progress usable on a compact Android viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.tap(find.byTooltip('View field progress'));
    await tester.pumpAndSettle();

    expect(find.text('Field progress'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Campus Reforestation Q2'),
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('monitoring-progress-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Campus Reforestation Q2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters the real map and routes to incident reporting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));

    // Open the filter panel to reveal the admin zone/status controls.
    await tester.tap(find.byTooltip('Filters'));
    await tester.pump();
    expect(find.text('All zones'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Incident'), findsOneWidget);

    // Status filter: keep only verified trees.
    await tester.tap(find.text('Verified'));
    await tester.pump();
    expect(find.text('TRE-0892'), findsOneWidget);
    expect(find.text('TRE-1056'), findsNothing);
    await tester.tap(find.text('All statuses'));
    await tester.pump();

    // Zone filter: keep only Zone II trees.
    await tester.tap(find.text('Zone II'));
    await tester.pump();
    expect(find.text('TRE-1056'), findsOneWidget);
    expect(find.text('TRE-0892'), findsNothing);
    await tester.tap(find.text('All zones'));
    await tester.pump();

    // Close the panel and open the bottom-sheet details for a tree.
    await tester.tap(find.byTooltip('Filters'));
    await tester.pump();
    await tester.tap(find.text('TRE-1508'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SELECTED TREE'), findsOneWidget);
    expect(find.text('Zone III'), findsOneWidget);
    expect(find.text('Start Verification'), findsOneWidget);

    // Incident report opens with the linked tree record.
    await tester.ensureVisible(find.text('Report incident'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report incident'));
    await tester.pumpAndSettle();
    expect(find.text('LINKED TREE RECORD'), findsOneWidget);
    expect(find.text('TRE-1508'), findsWidgets);
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('keeps authentication usable on a compact viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StaffAuthScreen()));

    expect(find.text('Login'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('collapses the calendar strip while scrolling down and restores '
      'it at the top', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    final strip = find.byKey(const Key('events-calendar-collapse'));
    final list = find.byKey(const Key('events-list'));
    final header = find.byKey(const Key('events-header'));

    // The strip is fully present at rest, and the top bar is always visible.
    expect(tester.getSize(strip).height, greaterThan(0));
    expect(find.byTooltip('Calendar'), findsOneWidget);

    final expandedHeaderHeight = tester.getSize(header).height;
    // The strip on its own, excluding the 18px gap above it.
    final bareStripHeight = tester.getSize(find.byType(CalendarStrip)).height;

    // Scrolling down collapses the strip so the event cards get the space.
    await tester.drag(list, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(tester.getSize(strip).height, 0);

    // The header must give back the strip *and* the 18px gap above it. When
    // that gap was a sibling of the collapse region it stayed put, so the
    // collapsed header kept 18 + 16px of dead green under the title.
    final reclaimed = expandedHeaderHeight - tester.getSize(header).height;
    expect(reclaimed, greaterThanOrEqualTo(bareStripHeight + 10));
    // The top bar is untouched by the collapse, and the cards now own the
    // reclaimed space.
    expect(find.byTooltip('Calendar'), findsOneWidget);
    expect(find.text('Tree planting & tagging'), findsWidgets);

    // Scrolling back up but staying below the top keeps it collapsed, so a
    // long list keeps its reclaimed space.
    await tester.drag(list, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(tester.getSize(strip).height, 0);

    // Reaching the very top brings the calendar back.
    await tester.drag(list, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(tester.getSize(strip).height, greaterThan(0));
  });

  testWidgets('cancelling the participation confirmation leaves the event '
      'unjoined', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.text('Tree planting & tagging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join this activity'));
    await tester.pumpAndSettle();

    // The dialog summarises the event before anything is recorded.
    expect(find.text('Confirm joining'), findsOneWidget);
    // The location shows both in the dialog and on the card behind it.
    expect(find.text('Sector 4 Reforestation Zone'), findsWidgets);
    expect(find.text('Joined'), findsNothing);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Join activity'), findsOneWidget);
    expect(find.text("You're in!"), findsNothing);
    expect(find.text('Joined'), findsNothing);
    // Back on the list, the card's own action still offers to join.
    expect(find.text('Join activity'), findsOneWidget);
  });

  testWidgets('confirmed participation shows a receipt that auto-dismisses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.text('Tree planting & tagging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join this activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm joining'));
    // Pump a bounded amount so the receipt is on screen but its 3s window has
    // not elapsed; pumpAndSettle here would wait the receipt out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The receipt is issued exactly once, and the card reflects the join.
    expect(find.text("You're in!"), findsOneWidget);
    expect(find.text('PARTICIPATION CONFIRMED'), findsOneWidget);
    expect(find.text('Tree planting & tagging'), findsWidgets);
    // The seeded schedule is generated relative to today, so the receipt's
    // date pill is asserted through the same helper the app renders with
    // rather than a fixed literal that would rot on any other day. The full
    // pill text is matched so the assertion cannot also pick up the header.
    expect(
      find.text(
        '${AppDate.scheduleHeading(DateTime.now())} · 08:00 AM - 11:30 AM',
      ),
      findsOneWidget,
    );
    expect(find.text('Leave activity'), findsOneWidget);

    // It clears itself after the receipt window, driven by the ticker so the
    // test needs no real-time delay.
    await tester.pump(kParticipationReceiptDuration);
    await tester.pumpAndSettle();
    expect(find.text("You're in!"), findsNothing);
    expect(find.text('Leave activity'), findsOneWidget);
  });

  testWidgets('participation receipt can be dismissed early by tapping it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.text('Tree planting & tagging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join this activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm joining'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("You're in!"), findsOneWidget);

    // Tapping the scrim dismisses it before the window elapses.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text("You're in!"), findsNothing);
  });

  testWidgets('participation receipt renders a long event title in full', (
    WidgetTester tester,
  ) async {
    const longTitle =
        'Verification feedback review and riparian buffer planting day';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ParticipationReceiptCard(
              event: LocalEvent(
                id: 'evt-long',
                date: DateTime(2026, 9, 6),
                time: '07:00 - 09:00',
                title: longTitle,
                location: 'Sector 4 Reforestation Belt',
                description: 'Long title regression coverage.',
                attendeeCount: 8,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The title has no maxLines and must keep wrapping to its natural height.
    // This guards against a future line cap silently truncating long names.
    expect(find.text(longTitle), findsOneWidget);
    expect(find.textContaining('…'), findsNothing);
    expect(tester.takeException(), isNull);

    // The hero title sits above the perforation, ahead of the detail rows.
    final titleY = tester.getTopLeft(find.text(longTitle)).dy;
    final locationY = tester
        .getTopLeft(find.text('Sector 4 Reforestation Belt'))
        .dy;
    expect(titleY, lessThan(locationY));
  });

  testWidgets('makes local event actions functional', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.text('Tree planting & tagging'));
    await tester.pumpAndSettle();
    expect(find.text('Join this activity'), findsOneWidget);

    await tester.tap(find.text('Join this activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm joining'));
    await tester.pumpAndSettle();
    expect(find.text('Leave activity'), findsOneWidget);
    await tester.pump(kParticipationReceiptDuration);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tree');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Tree planting & tagging'), findsOneWidget);

    // Move to tomorrow, where the seed places the audit review. The strip is
    // keyed by real date, so the tap survives any change to how days are
    // labelled or where the rolling window happens to start.
    final tomorrow = AppDate.dayOf(DateTime.now()).add(const Duration(days: 1));
    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-day-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification feedback review'), findsOneWidget);
  });

  testWidgets('replaces the tag scanner with live tracking', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsNothing);
    expect(find.byTooltip('Track my location'), findsOneWidget);
  });

  testWidgets('traces a route from a selected tree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('TRE-1508'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Start navigation'), findsOneWidget);
    final traceButton = find.ancestor(
      of: find.text('Start navigation'),
      matching: find.byType(OutlinedButton),
    );
    tester.widget<OutlinedButton>(traceButton).onPressed!();
    await tester.pump();

    expect(find.byKey(const ValueKey('tree-route')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers the analysis mode before locating the officer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    // Verification is contextual: open the map, select a tree, then start
    // verification from its details sheet.
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('TRE-1508'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SELECTED TREE'), findsOneWidget);
    await tester.ensureVisible(find.text('Start Verification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Verification'));
    await tester.pumpAndSettle();

    // The mode choice is the first thing shown, so the app is not holding a
    // GPS session open before the officer has committed to verifying.
    expect(find.text('How should this plant be analysed?'), findsOneWidget);
    expect(find.text('Manual Analysis'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('Finding your position…'), findsNothing);
  });

  testWidgets('the proximity check runs only after manual is chosen', (
    WidgetTester tester,
  ) async {
    // Temporarily off in the app; this test is about the gate's ordering, so it
    // switches the gate on for its duration and restores the shipped value.
    VerificationProximity.enforcementEnabled = true;
    addTearDown(() => VerificationProximity.enforcementEnabled = false);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('TRE-1508'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Start Verification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Verification'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manual Analysis'));
    // Not pumpAndSettle: the gate shows a progress indicator that spins for as
    // long as the real GPS call takes, so the tree never goes idle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The wizard must never open before the officer is confirmed to be at the
    // plant, so the location check comes before it.
    expect(find.text('Finding your position…'), findsOneWidget);
    expect(find.text('Plant status'), findsNothing);
  });

  testWidgets('links between login and sign-up via the bottom prompt', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StaffAuthScreen()));

    // Defaults to the login view with the sign-up prompt below the card.
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up.'), findsOneWidget);

    // Navigate into the registration flow.
    await tester.ensureVisible(find.text('Sign Up.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Up.'));
    await tester.pumpAndSettle();

    expect(find.text('Create staff profile'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Sign In.'), findsOneWidget);

    // And back to login.
    await tester.ensureVisible(find.text('Sign In.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In.'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  // ── Network connectivity ──────────────────────────────────────────────
  //
  // Mirrors the EcoTraceApp wiring (scope + banner host above the Navigator)
  // with an injectable controller so tests can drive offline/online flips
  // deterministically. The connectivity_plus platform channel is mocked
  // because an unmocked channel never settles in the widget-test runner.

  testWidgets('launches offline with no modal and reports the status', (
    WidgetTester tester,
  ) async {
    _mockConnectivity(tester, ['none']);
    final controller = ConnectivityController(
      probe: ScriptedProbe(true),
      heartbeat: null,
    );
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      _connectivityHarness(controller: controller, messengerKey: messengerKey),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // No modal or notice interrupts the launch while offline.
    expect(find.text('No internet connection'), findsNothing);
    expect(find.text('OK'), findsNothing);

    // The startup status is still resolved - the map header reports offline.
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Offline'), findsOneWidget);

    // A later offline -> online transition still raises the banner.
    controller.value = ConnectionStatus.online;
    await tester.pump();
    expect(find.text('Internet Connected'), findsOneWidget);

    // Let the snack bar auto-dismiss so no timers remain pending.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets(
    'flips the map header and shows snackbars on connectivity transitions',
    (WidgetTester tester) async {
      _mockConnectivity(tester, ['wifi']);
      final controller = ConnectivityController(
        probe: ScriptedProbe(true),
        heartbeat: null,
      );
      final messengerKey = GlobalKey<ScaffoldMessengerState>();

      await tester.pumpWidget(
        _connectivityHarness(
          controller: controller,
          messengerKey: messengerKey,
        ),
      );
      await tester.pump();

      // Map header starts online.
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Online'), findsOneWidget);

      // Losing the connection flips the header and raises a notice.
      controller.value = ConnectionStatus.offline;
      await tester.pump();
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);

      // Restoring the connection flips back and raises the connected banner.
      controller.value = ConnectionStatus.online;
      await tester.pump();
      expect(find.text('Internet Connected'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);

      // Let the snack bars auto-dismiss so no timers remain pending.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    },
  );

  // ── Reachability (transport up, internet down) ────────────────────────
  //
  // This is the regression that motivated the probe: `connectivity_plus`
  // reports `mobile` when data is switched on with no load or no plan, so a
  // transport-only check claims a connection the user cannot use.

  testWidgets(
    'treats an attached transport with a failing probe as unreachable',
    (WidgetTester tester) async {
      // Transport present, probe failing - the "data on but no internet" case.
      _mockConnectivity(tester, ['mobile']);
      final controller = ConnectivityController(
        probe: ScriptedProbe(false),
        heartbeat: null,
      );
      final messengerKey = GlobalKey<ScaffoldMessengerState>();

      await tester.pumpWidget(
        _connectivityHarness(
          controller: controller,
          messengerKey: messengerKey,
        ),
      );
      await tester.pump();
      // Let the seeded probe resolve and the debounce settle.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump(const Duration(milliseconds: 250));

      // Must NOT claim to be online, and must not use the offline wording.
      expect(find.text('Online'), findsNothing);
      expect(find.text('Offline'), findsNothing);
      expect(find.text('No internet'), findsOneWidget);
      expect(controller.value, ConnectionStatus.unreachable);
    },
  );

  testWidgets('recovers from unreachable once the probe starts succeeding', (
    WidgetTester tester,
  ) async {
    _mockConnectivity(tester, ['mobile']);
    final probe = ScriptedProbe(false);
    final controller = ConnectivityController(
      probe: probe,
      heartbeat: const Duration(seconds: 30),
    );
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      _connectivityHarness(controller: controller, messengerKey: messengerKey),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(controller.value, ConnectionStatus.unreachable);

    // The user tops up data / leaves the dead zone. The heartbeat re-probes
    // without any transport change event, which is the only way the app can
    // learn the internet came back.
    probe.answer = true;
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();

    expect(controller.value, ConnectionStatus.online);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Unmount before disposing: the banner host holds a listener, and
    // removeListener on an already-disposed notifier asserts. The heartbeat
    // timer is a real 30s timer, so leaving the controller alive would fail
    // the test on pending timers.
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test(
    'discards a probe that finishes after a newer transport evaluation',
    () async {
      // A probe is slow, and the transport changes while it is in flight. The
      // probe's "online" answer is older information than the "offline" the
      // newer evaluation already published, so applying it would show a
      // connection the user has actually lost.
      final events = _MockConnectivityPlatform(
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
        ['wifi'],
      );
      final probe = CompleterProbe();
      final controller = ConnectivityController(probe: probe, heartbeat: null);
      addTearDown(controller.dispose);

      final seen = <ConnectionStatus>[];
      controller.addListener(() => seen.add(controller.value));

      // Startup: transport present, so the probe starts and stalls.
      controller.initialize();
      await probe.started.future;

      // Transport drops while the probe is still outstanding.
      events.emit(['none']);
      // Past the debounce window, so the offline evaluation has been applied.
      await Future<void>.delayed(
        ConnectivityController.debounceDuration +
            const Duration(milliseconds: 50),
      );
      expect(controller.value, ConnectionStatus.offline);

      // The stale probe now reports success. It must not resurrect "online".
      probe.complete(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.value, ConnectionStatus.offline);
      expect(seen, isNot(contains(ConnectionStatus.online)));
      events.dispose();
    },
  );

  test(
    'probe reports unreachable rather than throwing on a dead endpoint',
    () async {
      // Port 9 (discard) on loopback refuses connections immediately and
      // identically on every platform, so this is a deterministic failure
      // without depending on the sandbox's network policy.
      final probe = HttpInternetProbe(
        endpoint: Uri.parse('http://127.0.0.1:9/'),
      );

      // A throwing probe would escape into the connectivity stream and take the
      // subscription down, so the contract is that failures resolve to false.
      expect(await probe.isReachable(), isFalse);
    },
  );
}

/// Probe whose single call stalls until the test completes it by hand, so a
/// transport change can be interleaved with an in-flight request.
class CompleterProbe implements InternetProbe {
  final Completer<bool> _result = Completer<bool>();

  /// Completes once the probe has actually been called, so the test knows an
  /// evaluation is genuinely in flight before it changes the transport.
  final Completer<void> started = Completer<void>();

  void complete(bool reachable) => _result.complete(reachable);

  @override
  Future<bool> isReachable() {
    if (!started.isCompleted) started.complete();
    return _result.future;
  }
}

/// Test double for the `connectivity_plus` platform channels.
///
/// Wraps both halves of the plugin: the `check` method channel and the
/// `connectivity_status` event channel, and can push new results onto the
/// stream on demand. Mirrors the plugin's own test harness, where `listen`
/// replays the initial value through the channel's success envelope.
class _MockConnectivityPlatform {
  static const String _statusChannel =
      'dev.fluttercommunity.plus/connectivity_status';
  static const MethodChannel _methodChannel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity',
  );

  /// Captured in the constructor: `TestDefaultBinaryMessengerBinding.instance`
  /// is not a constant expression, and the two closures below need it.
  final TestDefaultBinaryMessenger _messenger;

  _MockConnectivityPlatform(this._messenger, List<String> initial) {
    _current = List<String>.of(initial);

    _messenger.setMockMethodCallHandler(_methodChannel, (
      MethodCall call,
    ) async {
      if (call.method == 'check') return _current;
      return null;
    });

    _messenger.setMockMethodCallHandler(const MethodChannel(_statusChannel), (
      MethodCall call,
    ) async {
      if (call.method == 'listen') {
        // The framework only starts pushing once `listen` succeeds, so the
        // initial value has to be delivered in the same reply.
        await _messenger.handlePlatformMessage(
          _statusChannel,
          const StandardMethodCodec().encodeSuccessEnvelope(_current),
          (_) {},
        );
      }
      return null;
    });
  }

  late List<String> _current;

  /// Pushes a new transport reading to any active listener.
  Future<void> emit(List<String> results) async {
    _current = List<String>.of(results);
    await _messenger.handlePlatformMessage(
      _statusChannel,
      const StandardMethodCodec().encodeSuccessEnvelope(_current),
      (_) {},
    );
  }

  void dispose() {
    _messenger.setMockMethodCallHandler(_methodChannel, null);
    _messenger.setMockMethodCallHandler(
      const MethodChannel(_statusChannel),
      null,
    );
  }
}

/// Stubs the `connectivity_plus` platform channel for a widget test.
///
/// [results] is what `checkConnectivity()` returns, e.g. `['wifi']` or
/// `['none']`. The plugin's `MethodChannelConnectivity` invokes the method
/// named `check` on `dev.fluttercommunity.plus/connectivity`; the framework
/// (Flutter 3.47+) automatically encodes the handler's raw return value as a
/// success envelope, so the handler returns the plain list. The change stream
/// lives on a separate `connectivity_status` channel, which tests leave
/// unmocked. The handler is cleared when the test ends so later tests start
/// from a clean messenger.
void _mockConnectivity(WidgetTester tester, List<String> results) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    MethodCall call,
  ) async {
    if (call.method == 'check') return results;
    return null;
  });
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
}

/// Builds the same root scope + banner host wiring used by [EcoTraceApp],
/// but with a controllable controller and [AppShell] as the landing screen.
Widget _connectivityHarness({
  required ConnectivityController controller,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
}) {
  return MaterialApp(
    theme: EcoTraceTheme.light,
    scaffoldMessengerKey: messengerKey,
    home: const AppShell(),
    builder: (context, child) => AppConnectivityScope(
      notifier: controller,
      child: ConnectivityBannerHost(
        controller: controller,
        messengerKey: messengerKey,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
