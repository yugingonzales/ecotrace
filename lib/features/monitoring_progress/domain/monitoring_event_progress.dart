import 'dart:math' as math;

enum MonitoringEventStatus { active, completed }

/// A monitoring event's tree-verification progress at a point in time.

/// Normalized getters keep display values safe if a future API sends an
/// invalid target or an over-target verification count.
class MonitoringEventProgress {
  const MonitoringEventProgress({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.status,
    required this.targetTrees,
    required this.verifiedTrees,
    required this.activeStaff,
    required this.pendingReviews,
    required this.incidents,
  });

  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String location;
  final MonitoringEventStatus status;
  final int targetTrees;
  final int verifiedTrees;
  final int activeStaff;
  final int pendingReviews;
  final int incidents;

  int get safeTargetTrees => math.max(0, targetTrees);

  int get safeVerifiedTrees {
    if (safeTargetTrees == 0) return 0;
    return math.max(0, math.min(verifiedTrees, safeTargetTrees));
  }

  int get staffCount => math.max(0, activeStaff);
  int get pendingReviewCount => math.max(0, pendingReviews);
  int get incidentCount => math.max(0, incidents);
  int get remainingTrees => safeTargetTrees - safeVerifiedTrees;

  int get progressPercent {
    if (safeTargetTrees == 0) return 0;
    return (safeVerifiedTrees * 100 / safeTargetTrees).round();
  }

  String get dateRange => '$startDate – $endDate';
}

/// Aggregated progress across active monitoring events only.
class MonitoringProgressSummary {
  const MonitoringProgressSummary({
    required this.activeEventCount,
    required this.targetTrees,
    required this.verifiedTrees,
    required this.activeStaff,
    required this.pendingReviews,
    required this.incidents,
  });

  factory MonitoringProgressSummary.fromEvents(
    Iterable<MonitoringEventProgress> events,
  ) {
    var activeEventCount = 0;
    var targetTrees = 0;
    var verifiedTrees = 0;
    var activeStaff = 0;
    var pendingReviews = 0;
    var incidents = 0;

    for (final event in events) {
      if (event.status != MonitoringEventStatus.active) continue;
      activeEventCount += 1;
      targetTrees += event.safeTargetTrees;
      verifiedTrees += event.safeVerifiedTrees;
      activeStaff += event.staffCount;
      pendingReviews += event.pendingReviewCount;
      incidents += event.incidentCount;
    }

    return MonitoringProgressSummary(
      activeEventCount: activeEventCount,
      targetTrees: targetTrees,
      verifiedTrees: verifiedTrees,
      activeStaff: activeStaff,
      pendingReviews: pendingReviews,
      incidents: incidents,
    );
  }

  final int activeEventCount;
  final int targetTrees;
  final int verifiedTrees;
  final int activeStaff;
  final int pendingReviews;
  final int incidents;

  int get progressPercent {
    if (targetTrees <= 0) return 0;
    return (verifiedTrees * 100 / targetTrees).round();
  }
}
