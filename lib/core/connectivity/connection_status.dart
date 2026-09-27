/// Whether the device currently has usable network connectivity.
///
/// Defined in core so the map header, the sync dashboard, and the global
/// connectivity banner all consume the same primitive without depending on a
/// feature's internals.
///
/// [offline] and [unreachable] are deliberately distinct. The platform's
/// connectivity channel only reports which *transport* is attached
/// (wifi/mobile/ethernet), never whether traffic actually flows. A phone with
/// mobile data switched on but no load, no plan, or a captive portal still
/// reports `mobile`, so collapsing both into one boolean tells the user
/// "Connected" while every request is about to fail.
enum ConnectionStatus {
  /// A transport is attached *and* a real request succeeded.
  online,

  /// No transport is attached — Wi-Fi and mobile are both off.
  offline,

  /// A transport is attached, but the reachability probe failed. This is the
  /// "data is on but there is no internet" case, and it must never be shown as
  /// connected.
  unreachable,
}

extension ConnectionStatusX on ConnectionStatus {
  /// True only when traffic is genuinely flowing. Anything else means requests
  /// should be expected to fail, so features gate on this rather than on
  /// `status == ConnectionStatus.online` alone.
  bool get isUsable => this == ConnectionStatus.online;
}
