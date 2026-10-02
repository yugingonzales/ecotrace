import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../field_verification/domain/measurement_limits.dart';
import '../../../../field_verification/domain/tree_record.dart';
import '../../../../field_verification/domain/verification_draft.dart';
import '../../models/map_tree.dart';
import '../../widgets/verification/evidence_capture.dart';
import '../../widgets/verification/step_rail.dart';

/// The manual verification wizard.

/// Owns the draft, the current step and the step-by-step validation, and
/// returns a [TreeRecord] to the caller on submit.
class VerificationWizardScreen extends StatefulWidget {
  const VerificationWizardScreen({
    super.key,
    required this.tree,
    this.distanceFromTreeMeters,
  });

  final MapTree tree;

  /// Distance reported by the proximity gate, carried through for the record.
  final double? distanceFromTreeMeters;

  @override
  State<VerificationWizardScreen> createState() => _VerificationWizardScreenState();
}

class _VerificationWizardScreenState extends State<VerificationWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbh = TextEditingController();
  final _crown = TextEditingController();
  final _notes = TextEditingController();

  VerificationStep _step = VerificationStep.status;
  VerificationDraft _draft = const VerificationDraft();

  @override
  void dispose() {
    _dbh.dispose();
    _crown.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setStatus(PlantStatus value) {
    setState(() {
      _draft = _draft.copyWith(status: value);
      if (!value.requiresMeasurements) {
        _dbh.clear();
        _crown.clear();
        _draft = _draft.copyWith(clearMeasurements: true, clearPhotos: true);
      }
    });
  }

  /// Advances a step, persisting the measurements on the way past so values
  /// typed in step 2 survive a return trip from step 3.
  void _goTo(VerificationStep step) {
    if (step.index > _step.index && _step == VerificationStep.measurements) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      setState(() {
        _draft = _draft.copyWith(
          dbhCm: double.tryParse(_dbh.text.trim()),
          crownDimensionCm: double.tryParse(_crown.text.trim()),
        );
      });
    }
    setState(() => _step = step);
  }

  void _advanceFromStatus() {
    if (_draft.status == PlantStatus.missing) {
      setState(() => _step = VerificationStep.review);
      return;
    }
    _goTo(VerificationStep.measurements);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_draft.hasStatus) {
      setState(() => _step = VerificationStep.status);
      return;
    }
    if (_draft.needsEvidence && _draft.photoPaths.length < 3) {
      setState(() => _step = VerificationStep.evidence);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Take at least 3 photos before submitting.'),
          backgroundColor: EcoTraceColors.error,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _draft.toRecord(
        treeId: widget.tree.id,
        treeCode: widget.tree.id,
        species: widget.tree.species,
        latitude: widget.tree.lat,
        longitude: widget.tree.lng,
        distanceFromTreeMeters: widget.distanceFromTreeMeters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMissing = _draft.status == PlantStatus.missing;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EcoTraceColors.forest,
        foregroundColor: Colors.white,
        title: Text(
          widget.tree.id,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: StepRail(
                  labels: [
                    'Status',
                    'Measure',
                    'Evidence',
                    'Review',
                  ],
                  currentIndex: _step.index,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_step) {
                    VerificationStep.status => _StatusStep(
                      key: const ValueKey('step-status'),
                      selected: _draft.status,
                      onSelect: _setStatus,
                    ),
                    VerificationStep.measurements => _MeasurementStep(
                      key: const ValueKey('step-measure'),
                      dbh: _dbh,
                      crown: _crown,
                      notes: _notes,
                      isMissing: isMissing,
                    ),
                    VerificationStep.evidence => _EvidenceStep(
                      key: const ValueKey('step-evidence'),
                      photoPaths: _draft.photoPaths,
                      isMissing: isMissing,
                      onChanged: (paths) =>
                          setState(() => _draft = _draft.copyWith(photoPaths: paths)),
                    ),
                    VerificationStep.review => _ReviewStep(
                      key: const ValueKey('step-review'),
                      tree: widget.tree,
                      draft: _draft,
                    ),
                  },
                ),
              ),
              _WizardFooter(
                step: _step,
                onBack: _step == VerificationStep.status
                    ? null
                    : () => _goTo(VerificationStep.values[_step.index - 1]),
                onNext: switch (_step) {
                  VerificationStep.review => _submit,
                  VerificationStep.status => _advanceFromStatus,
                  _ => () => _goTo(VerificationStep.values[_step.index + 1]),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.step,
    required this.onBack,
    required this.onNext,
  });

  final VerificationStep step;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isSubmit = step == VerificationStep.review;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: EcoTraceColors.border)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: EcoTraceColors.forest,
                  side: const BorderSide(color: EcoTraceColors.forest, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: EcoTraceColors.forest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isSubmit ? 'Submit verification' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({super.key, required this.selected, required this.onSelect});

  final PlantStatus? selected;
  final ValueChanged<PlantStatus> onSelect;

  @override
  Widget build(BuildContext context) => ListView(
    key: key,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
    children: [
      const Text(
        'Plant status',
        style: TextStyle(
          color: Color(0xFF0A231C),
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'What did you find at the plant?',
        style: TextStyle(color: EcoTraceColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 18),
      for (final status in PlantStatus.values) ...[
        _StatusOption(
          status: status,
          isSelected: selected == status,
          onTap: () => onSelect(status),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final PlantStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (status) {
    PlantStatus.alive => Icons.park_rounded,
    PlantStatus.damaged => Icons.report_problem_rounded,
    PlantStatus.dead => Icons.heart_broken_rounded,
    PlantStatus.missing => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? EcoTraceColors.leaf : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? EcoTraceColors.forest : EcoTraceColors.border,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(_icon, color: EcoTraceColors.forest, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: const TextStyle(
                    color: Color(0xFF0A231C),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.description,
                  style: const TextStyle(
                    color: EcoTraceColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: EcoTraceColors.forest),
        ],
      ),
    ),
  );
}

class _MeasurementStep extends StatelessWidget {
  const _MeasurementStep({
    super.key,
    required this.dbh,
    required this.crown,
    required this.notes,
    required this.isMissing,
  });

  final TextEditingController dbh;
  final TextEditingController crown;
  final TextEditingController notes;
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    if (isMissing) {
      return ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        children: const [
          _MissingNotice(
            message:
                'The plant was recorded as missing, so there is nothing to measure. '
                'Submit the verification to finish.',
          ),
        ],
      );
    }
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        const Text(
          'Measurements',
          style: TextStyle(
            color: Color(0xFF0A231C),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: dbh,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'DBH — diameter at breast height',
            hintText: 'cm, e.g. 24.5',
            suffixText: 'cm',
          ),
          validator: (value) => _validate(
            value,
            'DBH',
            MeasurementLimits.maxDbhCm,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: crown,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Crown dimension',
            hintText: 'cm, e.g. 450',
            suffixText: 'cm',
          ),
          validator: (value) => _validate(
            value,
            'Crown dimension',
            MeasurementLimits.maxCrownCm,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes / observation',
            hintText: 'Anything worth recording about this plant',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// Validates a measurement entered in the field.
  ///
  static String? _validate(
    String? raw,
    String label,
    double maxCm,
  ) {
    final value = double.tryParse((raw ?? '').trim());
    if (value == null) return 'Enter $label';
    if (value <= 0) return '$label must be greater than 0';
    if (value > maxCm) return '$label cannot exceed ${maxCm.toStringAsFixed(0)}';
    return null;
  }
}

class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep({
    super.key,
    required this.photoPaths,
    required this.isMissing,
    required this.onChanged,
  });

  final List<String> photoPaths;
  final bool isMissing;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isMissing) {
      return ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        children: const [
          _MissingNotice(
            message:
                'A missing plant cannot be photographed, so no evidence is required. '
                'Submit the verification to finish.',
          ),
        ],
      );
    }
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        EvidenceCapture(photoPaths: photoPaths, onChanged: onChanged),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.tree,
    required this.draft,
  });

  final MapTree tree;
  final VerificationDraft draft;

  @override
  Widget build(BuildContext context) {
    final status = draft.status!;
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        const Text(
          'Review',
          style: TextStyle(
            color: Color(0xFF0A231C),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          rows: [
            _Row('Tree', tree.id),
            _Row('Species', tree.species),
            _Row('Status', status.label),
            if (status.requiresMeasurements)
              _Row('DBH', '${draft.dbhCm?.toStringAsFixed(1) ?? '—'} cm'),
            if (status.requiresMeasurements)
              _Row('Crown', '${draft.crownDimensionCm?.toStringAsFixed(1) ?? '—'} cm'),
            if (draft.notes.isNotEmpty) _Row('Notes', draft.notes),
            if (status.requiresEvidence)
              _Row('Photos', '${draft.photoPaths.length}'),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Submitting sends this for review. The map status updates once it is '
          'accepted.',
          style: TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: EcoTraceColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    row.label,
                    style: const TextStyle(
                      color: EcoTraceColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: const TextStyle(
                      color: Color(0xFF0A231C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (row != rows.last) const Divider(height: 12),
        ],
      ],
    ),
  );
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String value;
}

class _MissingNotice extends StatelessWidget {
  const _MissingNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: EcoTraceColors.lemon, width: 2),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: EcoTraceColors.forest),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF0A231C),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
