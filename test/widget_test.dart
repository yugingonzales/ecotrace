// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecotrace/main.dart';
import 'package:ecotrace/features/home/presentation/app_shell.dart';

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
    await tester.pump();
    expect(find.text('Sector 4\nReforestation Zone'), findsOneWidget);

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
    await tester.pump();
    expect(find.text('Sector 4\nReforestation Zone'), findsOneWidget);
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
    await tester.enterText(fields.at(0), 'T-104');
    await tester.enterText(fields.at(1), '24.6');
    await tester.enterText(fields.at(2), '5.2');
    await tester.ensureVisible(find.text('Save verification draft'));
    await tester.tap(find.text('Save verification draft'));
    await tester.pumpAndSettle();
    expect(
      find.text('Verification draft for T-104 saved locally.'),
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
}
