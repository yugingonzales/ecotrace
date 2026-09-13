// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecotrace/main.dart';
import 'package:ecotrace/features/home/presentation/app_shell.dart';
import 'package:ecotrace/core/connectivity/app_connectivity_scope.dart';
import 'package:ecotrace/core/connectivity/connection_status.dart';
import 'package:ecotrace/core/connectivity/connectivity_banner_host.dart';
import 'package:ecotrace/core/connectivity/connectivity_controller.dart';
import 'package:ecotrace/core/theme/app_theme.dart';

void main() {
  testWidgets('renders the animated splash then auth entry screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoTraceApp());

    // Splash screen is shown first with its branding.
    expect(find.text('EcoTrace'), findsOneWidget);
    expect(find.text('Environmental Tracking System'), findsOneWidget);

    // Advance through the staggered animation (~3.1s) and the route fade.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Username *'), findsOneWidget);
    expect(find.text('Password *'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
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

  testWidgets('keeps the shell usable at a phone-sized viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    expect(find.byTooltip('Start tree verification'), findsOneWidget);

    await tester.tap(find.byTooltip('Start tree verification'));
    await tester.pumpAndSettle();
    expect(find.text('Scan NFC or QR tag'), findsOneWidget);
    await tester.tap(find.byTooltip('Close scanner'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.tap(find.text('All records synced'));
    await tester.pumpAndSettle();
    expect(find.text('Sync dashboard'), findsOneWidget);
  });

  testWidgets('keeps the shell usable on a compact Android viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    expect(find.text('Today\'s schedule'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('UEP Catarman · Streets'), findsOneWidget);
    expect(find.text('TRE-0892'), findsOneWidget);
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

    await tester.pumpWidget(const EcoTraceApp());

    // Skip the splash sequence to reach the auth form.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Login'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('makes local event actions functional', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));

    await tester.tap(find.text('Tree planting & tagging'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm participation'), findsOneWidget);

    await tester.tap(find.text('Confirm participation'));
    await tester.pumpAndSettle();
    expect(find.text('Joined'), findsOneWidget);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tree');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Tree planting & tagging'), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();
    expect(find.text('Verification feedback review'), findsOneWidget);
  });

  testWidgets('validates and saves a manual verification draft', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.tap(find.byTooltip('Start tree verification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter tree details manually'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save verification draft'));
    await tester.pump();
    expect(find.text('Tree tag is required'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'TRE-0892');
    await tester.enterText(fields.at(1), '24.6');
    await tester.enterText(fields.at(2), '5.2');
    await tester.ensureVisible(find.text('Save verification draft'));
    await tester.tap(find.text('Save verification draft'));
    await tester.pumpAndSettle();
    expect(
      find.text('Verification draft for TRE-0892 saved locally.'),
      findsOneWidget,
    );
  });

  testWidgets('links between login and sign-up via the bottom prompt', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoTraceApp());

    // Skip the splash sequence to reach the auth form.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

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

  testWidgets('shows offline dialog at launch when offline', (
    WidgetTester tester,
  ) async {
    _mockConnectivity(tester, ['none']);
    final controller = ConnectivityController();
    final navigatorKey = GlobalKey<NavigatorState>();
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      _connectivityHarness(
        controller: controller,
        navigatorKey: navigatorKey,
        messengerKey: messengerKey,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsNothing);
  });

  testWidgets(
    'flips the map header and shows snackbars on connectivity transitions',
    (WidgetTester tester) async {
      _mockConnectivity(tester, ['wifi']);
      final controller = ConnectivityController();
      final navigatorKey = GlobalKey<NavigatorState>();
      final messengerKey = GlobalKey<ScaffoldMessengerState>();

      await tester.pumpWidget(
        _connectivityHarness(
          controller: controller,
          navigatorKey: navigatorKey,
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
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall call) async {
      if (call.method == 'check') return results;
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

/// Builds the same root scope + banner host wiring used by [EcoTraceApp],
/// but with a controllable controller and [AppShell] as the landing screen.
Widget _connectivityHarness({
  required ConnectivityController controller,
  required GlobalKey<NavigatorState> navigatorKey,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
}) {
  return MaterialApp(
    theme: EcoTraceTheme.light,
    navigatorKey: navigatorKey,
    scaffoldMessengerKey: messengerKey,
    home: const AppShell(),
    builder: (context, child) => AppConnectivityScope(
      notifier: controller,
      child: ConnectivityBannerHost(
        controller: controller,
        navigatorKey: navigatorKey,
        messengerKey: messengerKey,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
