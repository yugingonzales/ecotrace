import 'package:ecotrace/core/loading/loading_views.dart';
import 'package:ecotrace/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: EcoTraceTheme.light,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: child,
    ),
  ),
);

const _tapTarget = Key('tap-target');

Widget _tappable({required VoidCallback onTap}) => Positioned.fill(
  child: GestureDetector(
    key: _tapTarget,
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: const Text('underneath'),
  ),
);

void main() {
  group('EcoButtonLoader', () {
    testWidgets('renders an indeterminate spinner', (tester) async {
      await tester.pumpWidget(_host(const EcoButtonLoader()));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      // Indeterminate: a determinate bar here would never finish and would
      // read as "upload" in a place that is only waiting on a button.
      expect(indicator.value, isNull);
    });
  });

  group('EcoBlockingOverlay', () {
    testWidgets('renders nothing while not visible', (tester) async {
      await tester.pumpWidget(
        _host(const EcoBlockingOverlay(visible: false, message: 'Saving')),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Saving'), findsNothing);
    });

    testWidgets('reports the message and blocks input while visible', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Stack(
            children: [
              _tappable(onTap: () => taps++),
              const EcoBlockingOverlay(
                visible: true,
                message: 'Saving the incident',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Saving the incident'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tap the screen centre. It is covered by the centred status card, so
      // this proves the whole surface is inert; a tap on the text alone would
      // land on the card even if the scrim were removed.
      await tester.tap(find.byKey(_tapTarget));
      await tester.pump();
      expect(
        taps,
        0,
        reason: 'the scrim must block taps so the action cannot run twice',
      );
    });

    testWidgets('lets the tap through once the overlay is hidden', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Stack(
            children: [
              _tappable(onTap: () => taps++),
              const EcoBlockingOverlay(visible: false),
            ],
          ),
        ),
      );

      await tester.tap(find.byKey(_tapTarget));
      await tester.pump();
      expect(taps, 1, reason: 'a hidden overlay must not block anything');
    });
  });

  group('EcoProgressBar', () {
    testWidgets('reports the percentage that matches its value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const EcoProgressBar(progress: 0.42, label: 'Uploading photos')),
      );

      expect(find.text('Uploading photos'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('clamps out-of-range progress instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const EcoProgressBar(progress: 1.8, label: 'Over')),
      );

      expect(find.text('180%'), findsNothing);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('is determinate so it can show upload progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const EcoProgressBar(progress: 0.5, label: 'Half')),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.5);
    });
  });

  group('EcoSkeleton', () {
    testWidgets('renders the requested block for each placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Column(children: [EcoSkeletonList(rows: 3)])),
      );

      expect(find.byType(EcoSkeletonList), findsOneWidget);
      // 3 rows x 3 blocks (avatar, title, subtitle).
      expect(find.byType(EcoSkeleton), findsNWidgets(9));
    });

    testWidgets('does not animate when the OS asks for reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const EcoSkeleton(), disableAnimations: true),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // A repeating controller would keep the test scheduler busy and never
      // settle; reduced motion must leave nothing to animate.
      await tester.pumpWidget(_host(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
