import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    // `size` must be threaded into MediaQueryData: the card derives its maxHeight
    // from MediaQuery.sizeOf, and a zero-sized query collapses it to nothing.
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child ?? _harness(),
      ),
    );
    await tester.pump();
  }

  testWidgets('stays inside its maxHeight cap on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, size: const Size(320, 568));

    final size = tester.getSize(find.byType(TreeDetailsCard));
    // Guards the harness itself: without a real MediaQuery size the card
    // collapses to zero and every other assertion would pass vacuously.
    expect(size.height, greaterThan(0));
    expect(
      size.height,
      lessThanOrEqualTo(568 * TreeDetailsCard.maxHeightFraction),
    );
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
    await pumpAt(
      tester,
      size: const Size(320, 568),
      child: _harness(tree: long),
    );

    expect(tester.takeException(), isNull);
    // Ellipsis is a paint effect: the untruncated string stays in Text.data, so
    // asserting on the model text can never fail. Assert the render state.
    final chips = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(TreeDetailsCard),
            matching: find.byType(Text),
          ),
        )
        .where((t) => t.data != null && t.data!.contains('Carabao'))
        .toList();
    expect(chips, isNotEmpty, reason: 'the species chip should be rendered');

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(chips.first.data!),
    );
    expect(paragraph.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isTrue);

    // The raw data is still in the tree, just clipped by the chip.
    expect(long.species, contains('Carabao'));
  });

  testWidgets('wires every action to its callback', (
    WidgetTester tester,
  ) async {
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

    // Close sits at the top of the card and the actions at the bottom, so each
    // target is scrolled into view immediately before it is tapped. Scrolling
    // once up front would leave the earlier targets off-screen, and a tap that
    // lands on nothing still "succeeds" when warnIfMissed is false.
    Future<void> tapInView(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      await tester.pump();
    }

    await tapInView(find.byIcon(Icons.close_rounded));
    await tapInView(find.text('Start Verification'));
    await tapInView(find.text('Start navigation'));
    await tapInView(find.text('Report incident'));
    await tapInView(find.text('Clear route'));
    await tester.pumpAndSettle();

    expect(
      <int>[closed, verified, traced, reported, cleared],
      <int>[1, 1, 1, 1, 1],
    );
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
