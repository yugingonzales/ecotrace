import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'connection_status.dart';
import 'internet_probe.dart';

/// App-lifetime network-state holder.
class ConnectivityController extends ValueNotifier<ConnectionStatus> {
  ConnectivityController({
    Connectivity? connectivity,
    InternetProbe? probe,
    ConnectionStatus initialStatus = ConnectionStatus.unreachable,
    this.heartbeat = defaultHeartbeat,
  }) : _connectivity = connectivity ?? Connectivity(),
       _probe = probe ?? HttpInternetProbe(),
       super(initialStatus);

  final Connectivity _connectivity;
  final InternetProbe _probe;

  final Duration? heartbeat;

  /// How long to coalesce bursty platform events before publishing one.
  static const Duration debounceDuration = Duration(milliseconds: 600);

  static const Duration defaultHeartbeat = Duration(seconds: 30);

  bool _hasTransport = false;

  bool _probing = false;

  int _generation = 0;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;
  Timer? _heartbeatTimer;
  Future<void>? _initialized;

  /// Subscribes to connectivity changes and resolves the initial status.
  ///
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
    if (_probing) return;
    _probing = true;
    try {
      final reachable = await _probe.isReachable();
      if (generation != _generation) return;
      _publish(
        reachable ? ConnectionStatus.online : ConnectionStatus.unreachable,
      );
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
    _generation++;
    _stopHeartbeat();
    _debounce?.cancel();
    _debounce = null;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
