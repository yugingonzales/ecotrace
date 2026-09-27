import 'tree_record.dart';

/// The stages a manual verification moves through, in order.
enum VerificationStep { status, measurements, evidence, review }

/// Which analysis route the officer chose.
///
/// [automatic] exists in the UI but is not implemented: it is shown as
/// unavailable rather than hidden, so the field team knows the capability is
/// planned. Wiring it to a placeholder that invents measurements would corrupt
/// the dataset, so it stays inert until a real analysis backend exists.
enum AnalysisMode { manual, automatic }

extension AnalysisModeX on AnalysisMode {
  String get label => switch (this) {
    AnalysisMode.manual => 'Manual Analysis',
    AnalysisMode.automatic => 'Automatic Analysis',
  };

  String get blurb => switch (this) {
    AnalysisMode.manual => 'Record what you observe at the plant yourself',
    AnalysisMode.automatic => 'Not available yet — no analysis service connected',
  };

  bool get isAvailable => this == AnalysisMode.manual;
}

/// Everything the wizard has collected so far.
///
/// Held by the wizard's state object and turned into an immutable
/// [TreeRecord] on submit. Fields are nullable rather than defaulted because
/// "not answered yet" and "answered zero" are different states, and a missing
/// plant genuinely has no measurement.
class VerificationDraft {
  const VerificationDraft({this.status, this.dbhCm, this.crownDimensionCm, this.notes = '', this.photoPaths = const []});

  final PlantStatus? status;
  final double? dbhCm;
  final double? crownDimensionCm;
  final String notes;
  final List<String> photoPaths;

  bool get hasStatus => status != null;

  /// A missing plant is submitted without measurements or photos, so the
  /// wizard must not demand them.
  bool get needsMeasurements => status?.requiresMeasurements ?? true;

  bool get needsEvidence => status?.requiresEvidence ?? true;

  /// Merges changes into the draft.
  ///
  /// A plain `x ?? this.x` merge cannot express "clear this back to null",
  /// which the wizard needs when the status changes to missing and the
  /// previously typed measurements stop being meaningful. The explicit
  /// `clear*` flags express that intent without resorting to sentinel objects
  /// that would lose the field's type at the call site.
  VerificationDraft copyWith({
    PlantStatus? status,
    double? dbhCm,
    double? crownDimensionCm,
    String? notes,
    List<String>? photoPaths,
    bool clearMeasurements = false,
    bool clearPhotos = false,
  }) => VerificationDraft(
    status: status ?? this.status,
    dbhCm: clearMeasurements ? null : dbhCm ?? this.dbhCm,
    crownDimensionCm: clearMeasurements ? null : crownDimensionCm ?? this.crownDimensionCm,
    notes: notes ?? this.notes,
    photoPaths: clearPhotos ? const [] : photoPaths ?? this.photoPaths,
  );

  /// Builds the immutable record. Measurement values are only carried across
  /// for a plant that was actually present, so a stale value typed before the
  /// status was switched to missing cannot leak into the record.
  TreeRecord toRecord({
    required String treeId,
    required String treeCode,
    required String species,
    required double latitude,
    required double longitude,
    String? verifiedByStaffId,
    double? distanceFromTreeMeters,
    DateTime? verifiedAt,
  }) => TreeRecord(
    treeId: treeId,
    treeCode: treeCode,
    species: species,
    latitude: latitude,
    longitude: longitude,
    plantStatus: status!,
    verificationStatus: VerificationStatus.pending,
    measurementSource: MeasurementSource.manual,
    dbhCm: status!.requiresMeasurements ? dbhCm : null,
    crownDimensionCm: status!.requiresMeasurements ? crownDimensionCm : null,
    notes: notes.trim().isEmpty ? null : notes.trim(),
    photoEvidence: status!.requiresEvidence ? List.unmodifiable(photoPaths) : const [],
    verifiedByStaffId: verifiedByStaffId,
    verifiedAt: verifiedAt ?? DateTime.now(),
    distanceFromTreeMeters: distanceFromTreeMeters,
  );
}
