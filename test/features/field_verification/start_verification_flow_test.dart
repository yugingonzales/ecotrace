import 'package:ecotrace/features/field_verification/domain/tree_record.dart';
import 'package:ecotrace/features/field_verification/domain/verification_proximity.dart';
import 'package:ecotrace/features/home/presentation/models/map_tree.dart';
import 'package:ecotrace/features/home/presentation/screens/verification/start_verification_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tree = MapTree(
  id: 'TRE-0001',
  lat: 12.5113,
  lng: 124.6641,
  status: TreeStatus.unverified,
  planter: 'A. Reyes',
  species: 'Rain Tree',
  datePlanted: 'Mar 12, 2026',
  zone: 'Zone I',
);

/// A stand-in for the real GPS call, so the whole flow is testable on a
/// machine with no location fix and no device permission prompt.
class _FakePositionSource implements PositionSource {
  _FakePositionSource(this._result);

  final ProximityResult _result;
  int calls = 0;

  @override
  Future<ProximityResult> distanceTo({
    required double lat,
    required double lng,
  }) async {
    calls++;
    return _result;
  }
}

/// Opens the flow and returns whatever it pops back to the caller.
Future<TreeRecord?> pumpFlow(
  WidgetTester tester,
  PositionSource source,
) async {
  TreeRecord? popped;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<TreeRecord>(
                MaterialPageRoute(
                  builder: (_) => StartVerificationFlow(
                    tree: _tree,
                    positionSource: source,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  // The gate is disabled in the app so the interface can be tested without a
  // location fix. These tests are the gate's proof that it still works, so
  // they switch it back on for their duration and restore it afterwards.
  setUp(() => VerificationProximity.enforcementEnabled = true);
  tearDown(() => VerificationProximity.enforcementEnabled = false);

  testWidgets('the analysis mode is offered before anything is located', (
    tester,
  ) async {
    final source = _FakePositionSource(ProximityResult.withinRange(2));

    await pumpFlow(tester, source);

    expect(find.text('How should this plant be analysed?'), findsOneWidget);
    expect(find.text('Manual Analysis'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);

    // Nothing should be located until the officer commits, so the app is not
    // holding a GPS session open behind a screen they may back out of.
    expect(source.calls, 0);
  });

  testWidgets('choosing manual runs the check and then opens the wizard', (
    tester,
  ) async {
    final source = _FakePositionSource(ProximityResult.withinRange(2));

    await pumpFlow(tester, source);
    await tester.tap(find.text('Manual Analysis'));
    await tester.pumpAndSettle();

    // The gate confirms the officer is at the plant before the wizard opens.
    expect(source.calls, 1);
    expect(find.text('At the plant'), findsOneWidget);
    expect(find.text('Plant status'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Plant status'), findsOneWidget);
    expect(find.text('Alive'), findsOneWidget);
  });

  testWidgets('an out-of-range officer cannot reach the wizard', (tester) async {
    final source = _FakePositionSource(ProximityResult.outOfRange(140));

    await pumpFlow(tester, source);
    await tester.tap(find.text('Manual Analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Too far from the plant'), findsOneWidget);
    expect(find.text('Plant status'), findsNothing);

    // The copy quotes the live radius, so it must read 10 m, not the old 5 m.
    expect(find.textContaining('10 m of'), findsOneWidget);
  });

  testWidgets('a failed fix is reported as its own state, not as distance', (
    tester,
  ) async {
    final source = _FakePositionSource(
      const ProximityResult.failed(ProximityFailure.permissionDenied),
    );

    await pumpFlow(tester, source);
    await tester.tap(find.text('Manual Analysis'));
    await tester.pumpAndSettle();

    expect(find.textContaining('location access'), findsOneWidget);
    expect(find.text('Too far from the plant'), findsNothing);
  });

  testWidgets('the gate retries without re-showing the mode choice', (
    tester,
  ) async {
    final source = _FakePositionSource(ProximityResult.outOfRange(140));

    await pumpFlow(tester, source);
    await tester.tap(find.text('Manual Analysis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(source.calls, 2);
    // Staying on the gate rather than bouncing back to the mode choice: a
    // second round trip would ask the officer to choose a mode they already
    // chose, which is how a verification gets abandoned.
    expect(find.text('How should this plant be analysed?'), findsNothing);
    expect(find.text('Too far from the plant'), findsOneWidget);
  });

  testWidgets('with the gate disabled the wizard opens without locating', (
    tester,
  ) async {
    // This is the shipped configuration right now: the officer is testing the
    // interface on a desk, so no fix is requested and the wizard opens anyway.
    VerificationProximity.enforcementEnabled = false;
    final source = _FakePositionSource(ProximityResult.outOfRange(140));

    await pumpFlow(tester, source);
    await tester.tap(find.text('Manual Analysis'));
    await tester.pumpAndSettle();

    expect(source.calls, 0);
    expect(find.text('Plant status'), findsOneWidget);

    // No gate on the way in, and none remembered for the record.
    expect(find.text('At the plant'), findsNothing);
    expect(find.text('Too far from the plant'), findsNothing);
  });
}
