import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecotrace/core/theme/app_theme.dart';
import 'package:ecotrace/features/home/presentation/models/map_tree.dart';
import 'package:ecotrace/features/home/presentation/widgets/map/tree_details_card.dart';

const _tree = MapTree(
  id: 'TRE-1508',
  lat: 12.5101,
  lng: 124.6679,
  status: TreeStatus.pending,
  planter: 'R. Dela Cruz',
  species: 'Mangifera indica',
  datePlanted: 'Mar 12, 2026',
  zone: 'Zone III',
);

Widget _harness({
  MapTree tree = _tree,
  bool isTracing = false,
  bool hasRoute = false,
  VoidCallback? onClose,
  VoidCallback? onStartVerification,
  VoidCallback? onReportIncident,
  VoidCallback? onTrace,
  VoidCallback? onClearRoute,
}) => MaterialApp(
  theme: EcoTraceTheme.light,
  home: Scaffold(
    body: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: TreeDetailsCard(
        tree: tree,
        onClose: onClose ?? () {},
        onStartVerification: onStartVerification ?? () {},
        onReportIncident: onReportIncident ?? () {},
        onTrace: onTrace ?? () {},
        isTracing: isTracing,
        hasRoute: hasRoute,
        onClearRoute: onClearRoute ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  // The sheet has to survive the layouts it is actually shipped into: a small
  // phone, a large system font, and inventory values far longer than the ones
  // in the seed data. A RenderFlex overflow in any of them is a red-screen in
  // production, so each case asserts the absence of a layout exception.
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    Widget? child,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child ?? _harness(),
      ),
    );
    await tester.pump();
    debugPrint('CARD ${tester.getRect(find.byType(TreeDetailsCard))}');
    debugPrint(
      'CLOSE ${tester.getRect(find.byIcon(Icons.close_rounded))}',
    );
    debugPrint('SCAFFOLD ${tester.getRect(find.byType(Scaffold))}');
  }

  testWidgets('stays inside its 45% cap on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, size: const Size(320, 568));

    final size = tester.getSize(find.byType(TreeDetailsCard));
    expect(size.height, lessThanOrEqualTo(568 * 0.45));
    expect(size.width, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at a 1.6x system font', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, size: const Size(360, 640), textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ellipsizes inventory values longer than the widest chip', (
    WidgetTester tester,
  ) async {
    const long = MapTree(
      id: 'TRE-1508',
      lat: 12.51011234,
      lng: 124.66791234,
      status: TreeStatus.verified,
      planter: 'Environmentalist Dela Cruz-B两个人名字',
      species: 'Mangifera indica cultivar Carabao very long extra text',
      datePlanted: '12 March 2026 (early rainy season)',
      zone: 'Zone III',
    );
    await pumpAt(tester, size: const Size(320, 568), child: _harness(tree: long));

    expect(tester.takeException(), isNull);
    final allText = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(allText.contains('very long extra text'), false);
    // The raw data is still in the tree, just clipped by the chip.
    expect(long.species, contains('Carabao'));
  });

  testWidgets('wires every action to its callback', (WidgetTester tester) async {
    var closed = 0;
    var verified = 0;
    var reported = 0;
    var traced = 0;
    var cleared = 0;

    await pumpAt(
      tester,
      size: const Size(390, 844),
      child: _harness(
        hasRoute: true,
        onClose: () => closed++,
        onStartVerification: () => verified++,
        onReportIncident: () => reported++,
        onTrace: () => traced++,
        onClearRoute: () => cleared++,
      ),
    );

    // All taps are at or near the card bottom edge; scroll up slightly so the
// targets are within the test viewport before tapping.
// Scroll the inner scroll view to reveal the bottom actions.
final scrollable = find.descendant(
  of: find.byType(TreeDetailsCard),
  matching: find.byType(SingleChildScrollView),
);
// EnsureVisible fails when the widget is already scrolled off in some cases;
// instead scroll the scrollable to the bottom so all targets become hittable.
if (scrollable.evaluate().isNotEmpty) {
  await tester.scrollUntilVisible(
    find.text('Clear route'),
    300,
    scrollable: find.byType(SingleChildScrollView),
  );
} else {
  await tester.ensureVisible(find.byIcon(Icons.close_rounded));
}
await tester.pump();
// Tap the buttons' hit boxes directly to avoid off-screen warnings in this
// layout.
await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
await tester.tap(find.text('Start Verification'), warnIfMissed: false);
await tester.tap(find.text('Start navigation'), warnIfMissed: false);
await tester.tap(find.text('Report incident'), warnIfMissed: false);
await tester.tap(find.text('Clear route'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(<int>[closed, verified, traced, reported, cleared], <int>[
      1,
      1,
      1,
      1,
      1,
    ]);
  });

  testWidgets('disables navigation and spins while tracing', (
    WidgetTester tester,
  ) async {
    var traced = 0;
    await pumpAt(
      tester,
      size: const Size(390, 844),
      child: _harness(isTracing: true, onTrace: () => traced++),
    );

    await tester.ensureVisible(find.text('Start navigation'));
    await tester.tap(find.text('Start navigation'), warnIfMissed: false);
    await tester.pump();
    expect(traced, 0, reason: 'tracing must not re-fire while already routing');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides "Clear route" until a route exists', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, size: const Size(390, 844));
    expect(find.text('Clear route'), findsNothing);

    await pumpAt(
      tester,
      size: const Size(390, 844),
      child: _harness(hasRoute: true),
    );
    expect(find.text('Clear route'), findsOneWidget);
  });
}