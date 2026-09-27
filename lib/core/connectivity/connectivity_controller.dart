import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'connection_status.dart';
import 'internet_probe.dart';

/// App-lifetime network-state holder.
///
/// Owns the only `connectivity_plus` subscription in the app, seeds itself
/// with [checkConnectivity] at startup, and publishes a normalized
/// [ConnectionStatus] to exactly two listeners: the map header (via
/// [AppConnectivityScope]) and the global connectivity banner host.
///
/// The platform channel only reports the attached *transport*, never whether
/// traffic flows, so this controller requires two agreeing signals before it
/// will call a device online:
///  1. a non-`none` transport from `connectivity_plus`, and
///  2. a successful [InternetProbe] request.
///
/// A transport without a working probe resolves to
/// [ConnectionStatus.unreachable] rather than `online`. That is the difference
/// between a phone with mobile data switched on but no load, and a phone that
/// can actually reach the network.
///
/// Stream events are debounced so rapid Wi-Fi/mobile handoffs and platform
/// noise cannot flicker the UI. When the platform channel is unavailable
/// (widget tests), [initialize] silently keeps the seeded status instead of
/// crashing.
class ConnectivityController extends ValueNotifier<ConnectionStatus> {
  ConnectivityController({
    Connectivity? connectivity,
    InternetProbe? probe,
    ConnectionStatus initialStatus = ConnectionStatus.unreachable,
    this.heartbeat = defaultHeartbeat,
  })  : _connectivity = connectivity ?? Connectivity(),
        _probe = probe ?? HttpInternetProbe(),
        super(initialStatus);

  final Connectivity _connectivity;
  final InternetProbe _probe;

  /// How often to re-probe while a transport is attached. Catches the cases
  /// where the radio stays up but the internet stops working — an exhausted
  /// data plan, a captive portal, or a dropped upstream — none of which raise
  /// a connectivity change event.
  final Duration? heartbeat;

  /// How long to coalesce bursty platform events before publishing one.
  static const Duration debounceDuration = Duration(milliseconds: 600);

  static const Duration defaultHeartbeat = Duration(seconds: 30);

  /// The transport signal, kept separately from the published status. When a
  /// transport is present the heartbeat re-probes instead of doing nothing,
  /// which is what lets the status recover from [ConnectionStatus.unreachable]
  /// on its own.
  bool _hasTransport = false;

  /// Guards against overlapping probes. A heartbeat firing while the previous
  /// probe is still waiting on a 5s timeout would otherwise stack requests and
  /// let a stale result overwrite a fresh one.
  bool _probing = false;

  /// Monotonic token identifying the newest transport evaluation. A probe holds
  /// the generation it started under and discards its answer if the generation
  /// has moved on, which is what stops a slow request from resurrecting a
  /// connection the user has already lost.
  int _generation = 0;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;
  Timer? _heartbeatTimer;
  Future<void>? _initialized;

  /// Subscribes to connectivity changes and resolves the initial status.
  ///
  /// Idempotent; the returned future completes as soon as the initial
  /// [checkConnectivity] has settled so callers can react to the startup
  /// status without racing stream events.
  Future<void> initialize() {
    if (_initialized != null) return _initialized!;
    final completer = Completer<void>();
    _initialized = completer.future;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object _) {
        // No platform stream available (e.g. widget tests) — ignore.
      },
    );

    Future<void> seed() async {
      try {
        final result = await _connectivity.checkConnectivity();
        await _evaluate(result);
      } catch (_) {
        // Platform unavailable — keep the seeded status.
      }
    }

    unawaited(seed().whenComplete(completer.complete));
    return completer.future;
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () {
      _debounce = null;
      unawaited(_evaluate(result));
    });
  }

  /// Combines the transport signal with a reachability probe and publishes the
  /// result.
  Future<void> _evaluate(List<ConnectivityResult> result) async {
    // Every evaluation invalidates any probe still in flight. A probe takes up
    // to its 5s timeout, and a transport change during that window is newer
    // information than the probe's answer — without this, walking out of Wi-Fi
    // range mid-probe would publish a stale "online" over the fresh "offline".
    final generation = ++_generation;
    _hasTransport = result.hasConnectivity;
    if (!_hasTransport) {
      // No transport means no probe: a request cannot succeed, so spending the
      // timeout on one would only delay showing the offline state.
      _stopHeartbeat();
      _publish(ConnectionStatus.offline);
      return;
    }
    await _probeAndPublish(generation);
  }

  /// Runs the reachability probe and publishes the result, unless a newer
  /// evaluation has superseded [generation] in the meantime.
  Future<void> _probeAndPublish(int generation) async {
    // A probe is already in flight. Its result is still the best information
    // available and will be published unless it is superseded, so there is no
    // value in stacking a second concurrent request.
    if (_probing) return;
    _probing = true;
    try {
      final reachable = await _probe.isReachable();
      // A transport change (or a dispose) landed while the probe was awaiting.
      // Its verdict is now stale, and publishing it — or scheduling a
      // heartbeat from it — would override whatever the newer state decided.
      if (generation != _generation) return;
      _publish(
        reachable
            ? ConnectionStatus.online
            : ConnectionStatus.unreachable,
      );
      // The heartbeat runs in both outcomes. Restarting it even after a failure
      // is what lets the status recover on its own when the user tops up data,
      // walks out of a dead zone, or clears a captive portal — none of which
      // raise a transport change event.
      _startHeartbeat();
    } finally {
      _probing = false;
    }
  }

  /// Schedules the next reachability re-check, replacing any pending one.
  void _startHeartbeat() {
    if (heartbeat == null) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(heartbeat!, () {
      _heartbeatTimer = null;
      if (!_hasTransport) return;
      unawaited(_probeAndPublish(_generation));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _publish(ConnectionStatus status) {
    if (status != value) value = status;
  }

  @override
  void dispose() {
    // Bumping the generation orphans any probe still awaiting, so a request
    // that completes after disposal is discarded rather than publishing into a
    // disposed notifier.
    _generation++;
    _stopHeartbeat();
    _debounce?.cancel();
    _debounce = null;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
