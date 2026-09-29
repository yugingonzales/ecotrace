import 'package:ecotrace/features/field_verification/domain/measurement_limits.dart';
import 'package:ecotrace/features/field_verification/domain/tree_record.dart';
import 'package:ecotrace/features/field_verification/domain/verification_draft.dart';
import 'package:ecotrace/features/field_verification/domain/verification_proximity.dart';
import 'package:flutter_test/flutter_test.dart';

TreeRecord buildRecord(VerificationDraft draft) => draft.toRecord(
  treeId: 'TRE-0001',
  treeCode: 'TRE-0001',
  species: 'Rain Tree',
  latitude: 12.5113,
  longitude: 124.6641,
);

void main() {
  group('PlantStatus', () {
    test('missing is the only status that needs no evidence or measurements', () {
      expect(PlantStatus.missing.requiresEvidence, isFalse);
      expect(PlantStatus.missing.requiresMeasurements, isFalse);
      for (final status in [
        PlantStatus.alive,
        PlantStatus.damaged,
        PlantStatus.dead,
      ]) {
        expect(status.requiresEvidence, isTrue, reason: '$status');
        expect(status.requiresMeasurements, isTrue, reason: '$status');
      }
    });

    test('every status has a distinct label', () {
      final labels = PlantStatus.values.map((s) => s.label).toSet();
      expect(labels.length, PlantStatus.values.length);
    });
  });

  group('VerificationProximity', () {
    test('accepts a reading inside the radius', () {
      expect(
        VerificationProximity.isAcceptable(meters: 2.0, accuracy: 4.0),
        isTrue,
      );
    });

    test('rejects a reading far outside the radius', () {
      expect(
        VerificationProximity.isAcceptable(meters: 40.0, accuracy: 4.0),
        isFalse,
      );
    });

    test('a precise fix is judged on the radius alone', () {
      // 12 m reported with a 1 m-accurate fix, so the true position is at best
      // 11 m away — outside the 10 m radius under any reading of the error.
      expect(
        VerificationProximity.isAcceptable(meters: 12.0, accuracy: 1.0),
        isFalse,
      );
    });

    test('a sloppy fix is given the benefit of the doubt', () {
      // 11 m away but only accurate to 20 m — plausibly standing on the tree.
      expect(
        VerificationProximity.isAcceptable(meters: 11.0, accuracy: 20.0),
        isTrue,
      );
    });

    test('refuses a fix so inaccurate it proves nothing', () {
      expect(
        VerificationProximity.isAcceptable(meters: 0.0, accuracy: 95.0),
        isFalse,
        reason: 'standing on the tree but with a 95 m fix is not evidence',
      );
    });

    test('boundary case at exactly the radius with a perfect fix', () {
      expect(
        VerificationProximity.isAcceptable(
          meters: VerificationProximity.maxDistanceMeters,
          accuracy: 0,
        ),
        isTrue,
      );
    });

    test('the radius is 10 m', () {
      expect(VerificationProximity.maxDistanceMeters, 10.0);
    });
  });

  group('ProximityResult', () {
    test('a successful reading inside range is not a failure', () {
      final result = ProximityResult.withinRange(3.0);
      expect(result.isFailure, isFalse);
      expect(result.isWithinRange, isTrue);
      expect(result.meters, 3.0);
    });

    test('a failure carries no distance and is out of range', () {
      final result = ProximityResult.failed(
        ProximityFailure.permissionDeniedForever,
      );
      expect(result.isFailure, isTrue);
      expect(result.isWithinRange, isFalse);
      expect(result.meters, isNull);
    });
  });

  group('AnalysisMode', () {
    test('only manual analysis is available', () {
      expect(AnalysisMode.manual.isAvailable, isTrue);
      expect(AnalysisMode.automatic.isAvailable, isFalse);
    });
  });

  group('VerificationDraft', () {
    test('an empty draft demands both measurements and evidence', () {
      const draft = VerificationDraft();
      expect(draft.hasStatus, isFalse);
      expect(draft.needsMeasurements, isTrue);
      expect(draft.needsEvidence, isTrue);
    });

    test('a missing plant demands neither', () {
      const draft = VerificationDraft(status: PlantStatus.missing);
      expect(draft.needsMeasurements, isFalse);
      expect(draft.needsEvidence, isFalse);
    });

    test('copyWith can clear measurements, which a plain merge cannot', () {
      const draft = VerificationDraft(
        status: PlantStatus.alive,
        dbhCm: 24.5,
        crownDimensionCm: 450,
        photoPaths: ['/tmp/a.jpg'],
      );

      final cleared = draft.copyWith(clearMeasurements: true, clearPhotos: true);

      expect(cleared.dbhCm, isNull);
      expect(cleared.crownDimensionCm, isNull);
      expect(cleared.photoPaths, isEmpty);
      expect(cleared.status, PlantStatus.alive);
    });

    test('a missing plant cannot leak stale measurements into the record', () {
      // Reproduces the field case: the officer measures and photographs, then
      // realises at review that they are at the wrong plot.
      const draft = VerificationDraft(
        status: PlantStatus.missing,
        dbhCm: 24.5,
        crownDimensionCm: 450,
        photoPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      );

      final record = buildRecord(draft);

      expect(record.plantStatus, PlantStatus.missing);
      expect(record.dbhCm, isNull);
      expect(record.crownDimensionCm, isNull);
      expect(record.photoEvidence, isEmpty);
    });

    test('a completed record is pending and sourced from manual entry', () {
      const draft = VerificationDraft(
        status: PlantStatus.alive,
        dbhCm: 24.5,
        crownDimensionCm: 450,
        photoPaths: ['/tmp/a.jpg', '/tmp/b.jpg', '/tmp/c.jpg'],
      );

      final record = buildRecord(draft);

      expect(record.plantStatus, PlantStatus.alive);
      expect(record.verificationStatus, VerificationStatus.pending);
      expect(record.measurementSource, MeasurementSource.manual);
      expect(record.dbhCm, 24.5);
      expect(record.photoEvidence.length, 3);
      expect(record.verifiedAt, isNotNull);
    });

    test('blank notes are stored as null rather than an empty string', () {
      const draft = VerificationDraft(
        status: PlantStatus.alive,
        notes: '   ',
      );
      expect(buildRecord(draft).notes, isNull);
    });

    test('notes are trimmed', () {
      const draft = VerificationDraft(
        status: PlantStatus.alive,
        notes: '  buttress damage  ',
      );
      expect(buildRecord(draft).notes, 'buttress damage');
    });

    test('the photo list is unmodifiable so the record cannot drift', () {
      const draft = VerificationDraft(
        status: PlantStatus.alive,
        photoPaths: ['/tmp/a.jpg'],
      );
      expect(
        () => buildRecord(draft).photoEvidence.add('/tmp/b.jpg'),
        throwsUnsupportedError,
      );
    });
  });

  group('MeasurementLimits', () {
    test('limits are plausible for a campus tree', () {
      expect(MeasurementLimits.maxDbhCm, greaterThan(0));
      expect(
        MeasurementLimits.maxCrownCm,
        greaterThan(MeasurementLimits.maxDbhCm),
      );
    });

    test('both maxima are centimetres, so no conversion is needed', () {
      // Both fields are typed and stored in cm. If a conversion factor is
      // reintroduced, one of the two fields will read ten-fold too large —
      // the exact bug that made measurements un-submittable before.
      expect(MeasurementLimits.maxDbhCm, 500);
      expect(MeasurementLimits.maxCrownCm, 3000);
    });
  });
}
