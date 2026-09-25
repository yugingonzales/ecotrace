import 'package:ecotrace/core/theme/app_theme.dart';
import 'package:ecotrace/features/monitoring_progress/data/monitoring_progress_preview.dart';
import 'package:ecotrace/features/monitoring_progress/domain/monitoring_event_progress.dart';
import 'package:ecotrace/features/monitoring_progress/presentation/monitoring_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonitoringProgressSummary', () {
    test('aggregates only active events from the preview dataset', () {
      final summary = MonitoringProgressSummary.fromEvents(
        monitoringProgressPreview,
      );

      expect(summary.activeEventCount, 3);
      expect(summary.targetTrees, 4000);
      expect(summary.verifiedTrees, 2195);
      expect(summary.progressPercent, 55);
      expect(summary.activeStaff, 80);
      expect(summary.pendingReviews, 47);
      expect(summary.incidents, 12);
    });

    test('rounds per-event progress from the same source totals', () {
      final arbor = monitoringProgressPreview.first;

      expect(arbor.progressPercent, 75);
      expect(arbor.remainingTrees, 570);
      expect(arbor.dateRange, 'Apr 15, 2026 – May 15, 2026');
    });

    test('excludes completed events from the active summary', () {
      final summary = MonitoringProgressSummary.fromEvents([
        _event(
          status: MonitoringEventStatus.completed,
          target: 10,
          verified: 10,
        ),
      ]);

      expect(summary.activeEventCount, 0);
      expect(summary.targetTrees, 0);
      expect(summary.progressPercent, 0);
    });

    test('handles zero targets, over-target totals and negative counters', () {
      final zeroTarget = _event(target: 0, verified: 5);
      final negativeTarget = _event(target: -5, verified: 10);
      final overTarget = _event(
        target: 100,
        verified: 150,
        activeStaff: -1,
        pendingReviews: -2,
        incidents: -3,
      );

      expect(zeroTarget.progressPercent, 0);
      expect(zeroTarget.safeVerifiedTrees, 0);
      expect(zeroTarget.remainingTrees, 0);
      expect(negativeTarget.progressPercent, 0);
      expect(overTarget.progressPercent, 100);
      expect(overTarget.remainingTrees, 0);
      expect(overTarget.staffCount, 0);
      expect(overTarget.pendingReviewCount, 0);
      expect(overTarget.incidentCount, 0);
    });
  });

  testWidgets('renders the compact progress dashboard without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: EcoTraceTheme.light,
        home: const MonitoringProgressScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Field progress'), findsOneWidget);
    expect(find.text('3 active'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(find.text('2,195 of 4,000'), findsOneWidget);
    expect(find.text('Arbor Day Drive 2026'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Campus Reforestation Q2'), 220);
    expect(find.text('Campus Reforestation Q2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes accessible progress semantics for screen readers', (
    WidgetTester tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: EcoTraceTheme.light,
        home: const MonitoringProgressScreen(),
      ),
    );
    await tester.pump();

    final progressTrack = find.bySemanticsLabel(
      'Overall active event verification progress',
    );
    expect(progressTrack, findsOneWidget);
    expect(tester.getSemantics(progressTrack).value, '55%');

    // The handle must be released inside the test body, before the framework
    // asserts that no semantics handles leaked.
    handle.dispose();
  });
}

MonitoringEventProgress _event({
  MonitoringEventStatus status = MonitoringEventStatus.active,
  int target = 100,
  int verified = 0,
  int activeStaff = 0,
  int pendingReviews = 0,
  int incidents = 0,
}) => MonitoringEventProgress(
  id: 'E-TEST',
  name: 'Test event',
  startDate: 'Jan 1, 2026',
  endDate: 'Jan 31, 2026',
  location: 'Zone A',
  status: status,
  targetTrees: target,
  verifiedTrees: verified,
  activeStaff: activeStaff,
  pendingReviews: pendingReviews,
  incidents: incidents,
);
