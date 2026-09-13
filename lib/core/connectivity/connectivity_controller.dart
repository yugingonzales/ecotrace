import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'connection_status.dart';

/// App-lifetime network-state holder.
///
/// Owns the only `connectivity_plus` subscription in the app, seeds itself
/// with [checkConnectivity] at startup, and publishes a normalized
/// [ConnectionStatus] to exactly two listeners: the map header (via
/// [AppConnectivityScope]) and the global connectivity banner host.
///
/// Stream events are debounced so rapid Wi-Fi/mobile handoffs and platform
/// noise cannot flicker the UI. When the platform channel is unavailable
/// (widget tests), [initialize] silently keeps the seeded status instead of
/// crashing.
class ConnectivityController extends ValueNotifier<ConnectionStatus> {
  ConnectivityController({
    Connectivity? connectivity,
    ConnectionStatus initialStatus = ConnectionStatus.online,
  })  : _connectivity = connectivity ?? Connectivity(),
        super(initialStatus);

  final Connectivity _connectivity;

  /// How long to coalesce bursty platform events before publishing one.
  static const Duration debounceDuration = Duration(milliseconds: 600);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;
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
        _publish(_toStatus(result));
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
      _publish(_toStatus(result));
    });
  }

  /// Maps platform results to the app's binary status. A device is online
  /// when any non-`none` network interface is present.
  static ConnectionStatus _toStatus(List<ConnectivityResult> result) =>
      result.hasConnectivity
          ? ConnectionStatus.online
          : ConnectionStatus.offline;

  void _publish(ConnectionStatus status) {
    if (status != value) value = status;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
