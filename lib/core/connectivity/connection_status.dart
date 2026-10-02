/// Whether the device currently has usable network connectivity.
enum ConnectionStatus {
  /// A transport is attached *and* a real request succeeded.
  online,

  /// No transport is attached — Wi-Fi and mobile are both off.
  offline,

  unreachable,
}

extension ConnectionStatusX on ConnectionStatus {
  bool get isUsable => this == ConnectionStatus.online;
}
