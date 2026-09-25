# Field progress dashboard

The field-progress dashboard is a theme-native Flutter screen that summarises how
far active monitoring events have progressed toward their tree targets.

## Where it lives

- `lib/features/monitoring_progress/domain/monitoring_event_progress.dart` — typed
  `MonitoringEventProgress` / `MonitoringProgressSummary` models and the
  active-event aggregation used by both the UI and the tests.
- `lib/features/monitoring_progress/data/monitoring_progress_preview.dart` — the
  local preview dataset rendered by the screen.
- `lib/features/monitoring_progress/presentation/monitoring_progress_screen.dart` —
  the forest header, progress hero, summary strip and event-card list.
- `lib/features/monitoring_progress/presentation/widgets/` — the
  `ProgressOverview`, `ProgressTrack` and `EventProgressCard` building blocks.

## How it is reached

The bottom navigation's centre shortcut is now an insights action rather than a
scanner. Its tooltip is **"View field progress"**, and tapping it pushes
`MonitoringProgressScreen` onto the navigator from
`lib/features/home/presentation/app_shell.dart`.

Verification is unchanged and remains contextual: open **Map**, select a tree
(for example **TRE-1508**), then use **Start Verification** in the tree's detail
sheet. The scanner shortcut is no longer part of the navigation bar, so no
verification entry point was removed from the map flow.

## Preview-data provenance

The dashboard reads from a static, local dataset in
`monitoring_progress_preview.dart`. The figures were chosen to mirror the
operational sample in the web admin reference
(`C:\laragon\www\ecotrace_admin\src\components\modules\EventManagement.tsx`) and
to exercise the aggregation rules, not to represent live production telemetry:

| Active event | Verified / target | Share |
| --- | --- | --- |
| Arbor Day Drive 2026 | 1,680 / 2,250 | 75% |
| Coastal Mangrove Restoration | 515 / 1,250 | 41% |
| Campus Reforestation Q2 | 0 / 500 | 0% |
| **Active total** | **2,195 / 4,000** | **55%** |

The summary strip derives its **80 active staff**, **47 pending reviews** and
**12 incidents** from the same three active events. At least one completed
event is present in the dataset precisely so that active-only aggregation can be
verified — completed work must not leak into the headline numbers.

## Limitations

- **No networking.** Nothing is fetched, and no dependency was added. When the
  data layer is wired to a repository, only `monitoring_progress_preview.dart`
  needs to change; the presentation layer already consumes the typed models.
- **Snapshot, not live.** Values are fixed at build time. There is no polling,
  pull-to-refresh, or offline cache yet.
- **Read-only.** The cards surface progress only; there are no per-event actions,
  filters, or drill-down detail pages.
- **Percentage rounding is display-only.** The summary reports the raw verified
  and target totals, and each card rounds independently, so a card can read
  75% while the rounded active total is 55% of 4,000.
- **Progress tracks clamp to 0–100%.** Over-target totals display their true
  counts and a full track, and the raw ratio is intentionally not shown.
- **Invalid inputs are tolerated, not rejected.** Zero or negative targets yield
  0% instead of a division error, and negative counters are clamped to zero for
  display, so a malformed API response cannot crash the screen.

## Verification

```powershell
cd C:\flutter_workspace\ecotrace
dart format --output=none --set-exit-if-changed lib/features/monitoring_progress test/features/monitoring_progress
flutter analyze
flutter test
```

`test/features/monitoring_progress/monitoring_progress_test.dart` covers the
aggregation, per-event rounding, invalid-value handling, compact 320x568
rendering, and the exposed progress semantics.
`test/widget_test.dart` covers the centre-action navigation and the
map-selected-tree verification flow.
