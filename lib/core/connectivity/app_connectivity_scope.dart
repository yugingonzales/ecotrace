import 'package:flutter/widgets.dart';

import 'connection_status.dart';

/// Exposes the app-wide connectivity [ValueNotifier] to any screen.
///
class AppConnectivityScope
    extends InheritedNotifier<ValueNotifier<ConnectionStatus>> {
  const AppConnectivityScope({
    super.key,
    required ValueNotifier<ConnectionStatus> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Current status, defaulting to [ConnectionStatus.online] when the app
  /// was mounted without a scope (bare-shell widget tests).
  static ConnectionStatus statusOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppConnectivityScope>()
            ?.notifier
            ?.value ??
        ConnectionStatus.online;
  }
}
