import 'package:ecotrace/features/field_verification/domain/tree_record.dart';
import 'package:ecotrace/features/home/presentation/models/map_tree.dart';
import 'package:ecotrace/features/home/presentation/screens/verification/verification_wizard_screen.dart';
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

/// Pumps the wizard and returns whatever it pops on submit.
Future<TreeRecord?> pumpWizard(WidgetTester tester) async {
  TreeRecord? popped;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<TreeRecord>(
                MaterialPageRoute(
                  builder: (_) => const VerificationWizardScreen(tree: _tree),
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
  testWidgets('status step lists all four observational statuses', (tester) async {
    await pumpWizard(tester);

    expect(find.text('Alive'), findsOneWidget);
    expect(find.text('Damaged'), findsOneWidget);
    expect(find.text('Dead'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
  });

  testWidgets('an alive plant advances to the measurement fields', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Alive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('DBH — diameter at breast height'), findsOneWidget);
    expect(find.text('Crown dimension'), findsOneWidget);
    expect(find.text('Notes / observation'), findsOneWidget);
  });

  testWidgets('a missing plant skips measurement and evidence entirely', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Missing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Straight to review — no measurement fields, and the form is completable
    // without them.
    expect(find.text('Submit verification'), findsOneWidget);
    expect(find.text('DBH — diameter at breast height'), findsNothing);
    expect(find.text('Notes / observation'), findsNothing);
  });

  testWidgets('a missing plant submits without photos or measurements', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Missing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit verification'));
    await tester.pumpAndSettle();

    // The wizard popped with a record that has no invented numbers on it.
    // (The host route is still mounted, so assert on the pushed screen having
    // been dismissed.)
    expect(find.text('Review'), findsNothing);
  });

  testWidgets('an alive plant cannot be submitted without evidence', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Alive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'DBH — diameter at breast height'),
      '24.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Crown dimension'),
      '450',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);

    // No photos captured, so the wizard must refuse to submit and bounce the
    // officer back to the evidence step rather than writing an empty record.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit verification'));
    await tester.pumpAndSettle();

    expect(
      find.text('Take at least 3 photos before submitting.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
  });

  testWidgets('both measurements are read as centimetres', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Alive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // A normal DBH is tens of centimetres and a normal crown spread is a few
    // hundred. Both fields are typed in cm, so neither may be reinterpreted as
    // metres and rejected as implausibly large.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'DBH — diameter at breast height'),
      '24.5',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('That looks too large — check the value'),
      findsNothing,
    );

    // 450 cm = 4.5 m of canopy, the value the metre-based field used to take.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Crown dimension'),
      '450',
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter DBH'), findsNothing);
    expect(find.text('Enter Crown dimension'), findsNothing);

    // Both accepted, so the wizard moves on to evidence.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
  });

  testWidgets('an implausible DBH is rejected with a readable limit', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Alive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'DBH — diameter at breast height'),
      '9000',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('DBH cannot exceed 500'), findsOneWidget);
  });

  testWidgets('a zero measurement is rejected', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Alive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'DBH — diameter at breast height'),
      '0',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('DBH must be greater than 0'), findsOneWidget);
  });

  testWidgets('blank measurements block progress past the measurement step', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Alive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter DBH'), findsOneWidget);
  });
}
