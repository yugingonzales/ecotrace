import '../../../core/connectivity/connection_status.dart';

export '../../../core/connectivity/connection_status.dart'
    show ConnectionStatus;

enum SyncStatus { idle, syncing, synced, failed, conflict }

class SyncSummary {
  const SyncSummary({
    required this.connection,
    required this.status,
    required this.pendingCount,
    required this.failedCount,
    this.lastSyncedAt,
  });

  final ConnectionStatus connection;
  final SyncStatus status;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
}
