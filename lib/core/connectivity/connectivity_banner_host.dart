import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'connection_status.dart';
import 'connectivity_controller.dart';

/// Renders global network notices above every route of the app.
///
/// Notices are driven by [ConnectionStatus.isUsable] rather than by a
/// transport check, and the two failure states are worded differently because
/// the user's next action differs:
/// - no usable connection → offline → online transition → "Internet Connected".
/// - usable → any failure → "No internet connection".
/// - failure → usable → "Internet Connected".
///
/// [ConnectionStatus.unreachable] — a transport attached but the reachability
/// probe failing, e.g. mobile data on with no load — is deliberately *not*
/// reported as connected, and gets its own "No internet access" wording to
/// distinguish "nothing is attached" from "something is attached but the
/// internet does not work".
///
/// Startup connectivity is resolved silently (no dialog); the status simply
/// seeds the map header / sync indicators, and the first transition after
/// launch raises a snack bar.
///
/// Lives in `MaterialApp.builder` (above the Navigator) so the notices cover
/// the splash screen, auth flow, shell, and every pushed route.
class ConnectivityBannerHost extends StatefulWidget {
  const ConnectivityBannerHost({
    super.key,
    required this.controller,
    required this.messengerKey,
    required this.child,
  });

  final ConnectivityController controller;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<ConnectivityBannerHost> createState() =>
      _ConnectivityBannerHostState();
}

class _ConnectivityBannerHostState extends State<ConnectivityBannerHost> {
  /// Conservative until [initialize] resolves, so the first real transition
  /// is still reported.
  ConnectionStatus _previous = ConnectionStatus.unreachable;
  bool _startupResolved = false;

  @override
  void initState() {
    super.initState();
    _previous = widget.controller.value;
    widget.controller.addListener(_onStatusChanged);
    unawaited(_resolveStartup());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStatusChanged);
    super.dispose();
  }

  Future<void> _resolveStartup() async {
    await widget.controller.initialize();
    if (!mounted) return;
    _startupResolved = true;
    _previous = widget.controller.value;
  }

  void _onStatusChanged() {
    if (!_startupResolved) return;
    final current = widget.controller.value;
    final wasUsable = _previous.isUsable;
    _previous = current;

    if (current.isUsable && !wasUsable) {
      _showConnectedNotice();
    } else if (!current.isUsable && wasUsable) {
      _showFailureNotice(current);
    }
  }

  void _showConnectedNotice() {
    _showSnackBar(
      message: 'Internet Connected',
      backgroundColor: EcoTraceColors.forest,
    );
  }

  /// Distinguishes "no transport at all" from "transport up but the internet
  /// is not there", because only the second is fixed by enabling data or
  /// leaving a dead zone.
  void _showFailureNotice(ConnectionStatus status) {
    final unreachable = status == ConnectionStatus.unreachable;
    _showSnackBar(
      message: unreachable
          ? 'No internet access'
          : 'No internet connection',
      backgroundColor: EcoTraceColors.error,
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          duration: const Duration(milliseconds: 2500),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}