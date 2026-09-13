import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'connection_status.dart';
import 'connectivity_controller.dart';

/// Renders global network notices above every route of the app.
///
/// - Startup resolves offline → non-dismissable-by-background "No internet
///   connection" dialog.
/// - offline → online transition → short "Internet Connected" snack bar.
/// - online → offline transition while running → "No internet connection"
///   snack bar.
///
/// Lives in `MaterialApp.builder` (above the Navigator) so the notices cover
/// the splash screen, auth flow, shell, and every pushed route.
class ConnectivityBannerHost extends StatefulWidget {
  const ConnectivityBannerHost({
    super.key,
    required this.controller,
    required this.navigatorKey,
    required this.messengerKey,
    required this.child,
  });

  final ConnectivityController controller;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<ConnectivityBannerHost> createState() =>
      _ConnectivityBannerHostState();
}

class _ConnectivityBannerHostState extends State<ConnectivityBannerHost> {
  ConnectionStatus _previous = ConnectionStatus.online;
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
    if (_previous == ConnectionStatus.offline) {
      await _showStartupDialog();
    }
  }

  void _onStatusChanged() {
    if (!_startupResolved) return;
    final current = widget.controller.value;
    final wasOffline = _previous == ConnectionStatus.offline;
    _previous = current;

    if (current == ConnectionStatus.offline && !wasOffline) {
      _showOfflineNotice();
    } else if (current == ConnectionStatus.online && wasOffline) {
      _showConnectedNotice();
    }
  }

  Future<void> _showStartupDialog() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    await showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: EcoTraceColors.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: EcoTraceColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wifi_off_rounded,
            color: EcoTraceColors.error,
            size: 28,
          ),
        ),
        title: const Text(
          'No internet connection',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Connect to the internet to load the campus map '
          'and keep your records in sync.',
          style: TextStyle(color: EcoTraceColors.muted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: EcoTraceColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectedNotice() {
    _showSnackBar(
      message: 'Internet Connected',
      backgroundColor: EcoTraceColors.forest,
    );
  }

  void _showOfflineNotice() {
    _showSnackBar(
      message: 'No internet connection',
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
