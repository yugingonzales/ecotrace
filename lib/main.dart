import 'dart:async';

import 'package:flutter/material.dart';

import 'core/connectivity/app_connectivity_scope.dart';
import 'core/connectivity/connectivity_banner_host.dart';
import 'core/connectivity/connectivity_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

/// Builds and runs [EcoTraceApp], the campus tree-tracking PWA.
///
/// Widget tests that only care about [AppShell] or auth screens can still
/// mount `MaterialApp(home: …)` directly without the connectivity scaffold.
void main() => runApp(const EcoTraceApp());

class EcoTraceApp extends StatefulWidget {
  const EcoTraceApp({super.key, this.connectivityController});

  /// Optional controller injection for tests that need to drive the
  /// connectivity banner deterministically.
  final ConnectivityController? connectivityController;

  @override
  State<EcoTraceApp> createState() => _EcoTraceAppState();
}

class _EcoTraceAppState extends State<EcoTraceApp> {
  late final ConnectivityController _connectivity =
      widget.connectivityController ?? ConnectivityController();
  late final bool _ownsConnectivity =
      widget.connectivityController == null;

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    unawaited(_connectivity.initialize());
  }

  @override
  void dispose() {
    if (_ownsConnectivity) _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrace',
      debugShowCheckedModeBanner: false,
      theme: EcoTraceTheme.light,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      home: const SplashScreen(),
      builder: (context, child) => AppConnectivityScope(
        notifier: _connectivity,
        child: ConnectivityBannerHost(
          controller: _connectivity,
          navigatorKey: _navigatorKey,
          messengerKey: _messengerKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
