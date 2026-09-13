/// Whether the device currently has network connectivity.
///
/// Defined in core so the map header, the sync dashboard, and the global
/// connectivity banner all consume the same primitive without depending on a
/// feature's internals.
enum ConnectionStatus { online, offline }
