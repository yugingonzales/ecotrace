import '../domain/monitoring_event_progress.dart';

/// Local preview of the active event progress records exposed by the
/// EcoTrace admin portal. Replace this source when a real API is available.
const List<MonitoringEventProgress> monitoringProgressPreview = [
  MonitoringEventProgress(
    id: 'E001',
    name: 'Arbor Day Drive 2026',
    startDate: 'Apr 15, 2026',
    endDate: 'May 15, 2026',
    location: 'Zone A – Main Campus',
    status: MonitoringEventStatus.active,
    targetTrees: 2250,
    verifiedTrees: 1680,
    activeStaff: 45,
    pendingReviews: 38,
    incidents: 7,
  ),
  MonitoringEventProgress(
    id: 'E002',
    name: 'Earth Month Campaign',
    startDate: 'Apr 1, 2026',
    endDate: 'Apr 30, 2026',
    location: 'Zone B – Annex Field',
    status: MonitoringEventStatus.active,
    targetTrees: 1000,
    verifiedTrees: 420,
    activeStaff: 20,
    pendingReviews: 6,
    incidents: 3,
  ),
  MonitoringEventProgress(
    id: 'E003',
    name: 'Campus Reforestation Q2',
    startDate: 'May 1, 2026',
    endDate: 'Jun 30, 2026',
    location: 'Zone C – Hillside Reserve',
    status: MonitoringEventStatus.active,
    targetTrees: 750,
    verifiedTrees: 95,
    activeStaff: 15,
    pendingReviews: 3,
    incidents: 2,
  ),
];
