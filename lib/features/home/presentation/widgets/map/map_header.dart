import 'package:flutter/material.dart';

import '../../../../../core/connectivity/connection_status.dart';
import '../../../../../core/theme/app_theme.dart';

class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    required this.isSatellite,
    required this.connection,
    required this.onToggleLayers,
  });

  final bool isSatellite;

  /// The current network state. Three states rather than a bool because
  /// "transport attached but the internet is not reachable" is the case where
  /// a binary flag would tell the user the map is online while every tile
  /// request fails.
  final ConnectionStatus connection;
  final VoidCallback onToggleLayers;

  /// Label, colour, and status are derived together so a new
  /// [ConnectionStatus] cannot be added without the header also being
  /// updated — an unmapped value falls back to the "unreachable" wording
  /// rather than silently claiming a working connection.
  String get _label => switch (connection) {
        ConnectionStatus.online => 'Online',
        ConnectionStatus.offline => 'Offline',
        ConnectionStatus.unreachable => 'No internet',
      };

  Color get _connectionColor => switch (connection) {
        ConnectionStatus.online => const Color(0xFFA3E635),
        ConnectionStatus.offline => EcoTraceColors.error,
        // Amber rather than red: the radio is up, so this is recoverable
        // without touching the network toggle.
        ConnectionStatus.unreachable => EcoTraceColors.lemon,
      };

  @override
  Widget build(BuildContext context) {
    final connectionColor = _connectionColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: EcoTraceColors.forest.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18)],
      ),
      child: Row(
        children: [
          Tooltip(
            message: isSatellite
                ? 'Switch to street map'
                : 'Switch to satellite view',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleLayers,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSatellite
                        ? const Color(0xFFBFDBFF)
                        : EcoTraceColors.lemon,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSatellite
                        ? Icons.satellite_alt_rounded
                        : Icons.layers_outlined,
                    color: isSatellite
                        ? const Color(0xFF1D4ED8)
                        : EcoTraceColors.forest,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EcoTrace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isSatellite
                      ? 'UEP Catarman · Satellite'
                      : 'UEP Catarman · Streets',
                  style: const TextStyle(
                    color: Color(0xFFA3C2B5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.circle, size: 7, color: connectionColor),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: connectionColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

