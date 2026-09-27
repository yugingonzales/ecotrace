import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../field_verification/domain/tree_record.dart';
import '../../../../field_verification/domain/verification_proximity.dart';
import '../../models/map_tree.dart';
import 'analysis_mode_screen.dart';
import 'verification_wizard_screen.dart';

/// Entry point for "Start Verification".
///
/// Enforces that the officer is standing at the plant before the wizard opens,
/// then runs the mode choice and the manual wizard. Returns the completed
/// [TreeRecord] to the caller, or null if the officer backed out.
class StartVerificationFlow extends StatefulWidget {
  const StartVerificationFlow({
    super.key,
    required this.tree,
    this.positionSource,
  });

  final MapTree tree;
  final PositionSource? positionSource;

  @override
  State<StartVerificationFlow> createState() => _StartVerificationFlowState();
}

class _StartVerificationFlowState extends State<StartVerificationFlow> {
  late final PositionSource _source = widget.positionSource ?? GeolocatorPositionSource();
  bool _checking = true;
  ProximityResult? _result;

  @override
  void initState() {
    super.initState();
    _checkProximity();
  }

  Future<void> _checkProximity() async {
    final result = await _source.distanceTo(
      lat: widget.tree.lat,
      lng: widget.tree.lng,
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _continueToMode() async {
    // The mode choice and the wizard are pushed as one unit so the wizard is
    // never reachable without having passed the proximity check.
    final record = await Navigator.of(context).push<TreeRecord>(
      MaterialPageRoute(
        builder: (_) => _ModeAndWizard(
          tree: widget.tree,
          distanceMeters: _result?.meters,
        ),
      ),
    );
    if (record != null && mounted) Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return _scaffold(const _LocatingState());
    return _scaffold(_GateState(
      key: const ValueKey('gate'),
      result: _result!,
      onRetry: _checkProximity,
      onProceed: _continueToMode,
    ));
  }

  Widget _scaffold(Widget child) => Scaffold(
    appBar: AppBar(
      backgroundColor: EcoTraceColors.forest,
      foregroundColor: Colors.white,
      title: Text(
        'Verify ${widget.tree.id}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(child: child),
  );
}

class _ModeAndWizard extends StatefulWidget {
  const _ModeAndWizard({required this.tree, this.distanceMeters});

  final MapTree tree;
  final double? distanceMeters;

  @override
  State<_ModeAndWizard> createState() => _ModeAndWizardState();
}

class _ModeAndWizardState extends State<_ModeAndWizard> {
  bool _manual = false;

  @override
  Widget build(BuildContext context) {
    if (_manual) {
      return VerificationWizardScreen(
        tree: widget.tree,
        distanceFromTreeMeters: widget.distanceMeters,
      );
    }
    return AnalysisModeScreen(
      treeId: widget.tree.id,
      species: widget.tree.species,
      onManualChosen: (_) => setState(() => _manual = true),
    );
  }
}

class _LocatingState extends StatelessWidget {
  const _LocatingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: EcoTraceColors.forest),
        SizedBox(height: 18),
        Text(
          'Finding your position…',
          style: TextStyle(
            color: EcoTraceColors.forest,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Step closer to the plant',
          style: TextStyle(color: EcoTraceColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _GateState extends StatelessWidget {
  const _GateState({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onProceed,
  });

  final ProximityResult result;
  final VoidCallback onRetry;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    if (result.isFailure) {
      return _FailureNotice(failure: result.failure!, onRetry: onRetry);
    }
    if (result.isWithinRange) {
      return _WithinRangeNotice(
        meters: result.meters!,
        onProceed: onProceed,
      );
    }
    return _OutOfRangeNotice(meters: result.meters!, onRetry: onRetry);
  }
}

class _WithinRangeNotice extends StatelessWidget {
  const _WithinRangeNotice({required this.meters, required this.onProceed});

  final double meters;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on_rounded,
              color: EcoTraceColors.forest, size: 54),
          const SizedBox(height: 16),
          Text(
            'At the plant',
            style: TextStyle(
              color: EcoTraceColors.forest,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${meters.toStringAsFixed(1)} m from the recorded position',
            style: const TextStyle(color: EcoTraceColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: onProceed,
              style: FilledButton.styleFrom(
                backgroundColor: EcoTraceColors.forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Start verification',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OutOfRangeNotice extends StatelessWidget {
  const _OutOfRangeNotice({required this.meters, required this.onRetry});

  final double meters;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wrong_location_rounded,
              color: EcoTraceColors.error, size: 54),
          const SizedBox(height: 16),
          const Text(
            'Too far from the plant',
            style: TextStyle(
              color: Color(0xFF0A231C),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are ${meters.toStringAsFixed(0)} m away. Verification must be '
            'carried out within '
            '${VerificationProximity.maxDistanceMeters.toStringAsFixed(0)} m of '
            'the plant, so the measurements describe the right tree.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: EcoTraceColors.forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Check again',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.failure, required this.onRetry});

  final ProximityFailure failure;
  final VoidCallback onRetry;

  String get _message => switch (failure) {
    ProximityFailure.locationServicesDisabled =>
      'Location services are switched off on this device. Turn them on to verify a plant.',
    ProximityFailure.permissionDenied =>
      'EcoTrace needs location access to confirm you are at the plant.',
    ProximityFailure.permissionDeniedForever =>
      'Location access is blocked for EcoTrace. Enable it in Settings to verify a plant.',
    ProximityFailure.fixUnavailable =>
      'Could not get a position fix. Move into the open sky and try again.',
  };

  IconData get _icon => switch (failure) {
    ProximityFailure.locationServicesDisabled => Icons.gps_off_rounded,
    ProximityFailure.permissionDenied ||
    ProximityFailure.permissionDeniedForever => Icons.lock_outline_rounded,
    ProximityFailure.fixUnavailable => Icons.satellite_alt_rounded,
  };

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: EcoTraceColors.error, size: 50),
          const SizedBox(height: 16),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0A231C),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: EcoTraceColors.forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Try again',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    ),
  );
}
