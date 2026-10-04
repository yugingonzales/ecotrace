import 'dart:math' as math;

/// The live allocation for one participant in a field event.
class EventQuota {
  const EventQuota({
    required this.targetTrees,
    required this.participantCount,
    required this.verifiedTrees,
    this.previousParticipantCount,
  });

  final int targetTrees;
  final int participantCount;
  final int verifiedTrees;
  final int? previousParticipantCount;

  int get safeTargetTrees => math.max(0, targetTrees);
  int get safeParticipantCount => math.max(1, participantCount);
  int get assignedTrees => safeTargetTrees == 0
      ? 0
      : (safeTargetTrees + safeParticipantCount - 1) ~/ safeParticipantCount;
  int get safeVerifiedTrees =>
      math.min(math.max(0, verifiedTrees), assignedTrees);
  int get remainingTrees => math.max(0, assignedTrees - safeVerifiedTrees);
  bool get quotaDropped =>
      previousParticipantCount != null &&
      assignedTrees < _quotaFor(previousParticipantCount!);

  int _quotaFor(int count) {
    final safeCount = math.max(1, count);
    return safeTargetTrees == 0
        ? 0
        : (safeTargetTrees + safeCount - 1) ~/ safeCount;
  }

  /// Pure calculation used by UI and tests. A missing participant count still
  /// yields a safe allocation instead of dividing by zero.
  static int calculate({required int targetTrees, required int participants}) {
    final target = math.max(0, targetTrees);
    final count = math.max(1, participants);
    return target == 0 ? 0 : (target + count - 1) ~/ count;
  }
}
