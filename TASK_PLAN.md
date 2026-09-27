# EcoTrace — Optimization & Feature Task Plan

**Created:** 2026-09-27 · **Source:** `CODE_AUDIT_2026-09-27.md`

This is the living work queue. **Check this file before starting any task** — if a
task is ✅, it is done and must not be rebuilt. Add a line to the *Progress log*
at the bottom every time you finish or change something.

Legend: ⬜ not started · 🔧 in progress · ✅ done & verified (`flutter analyze` clean
+ `flutter test` green) · ⛔ blocked (needs a decision/contract) · 🚫 not doing

## Ground rules

- Gates after every task: `flutter analyze` (clean) and `flutter test` (currently **57/57** green).
- Do not invent backend endpoints, credentials, schema fields, or OpenCV behavior.
  Leave a clearly marked adapter boundary instead.
- Android is the only target platform.
- Preserve the theme/visual language unless a design change is requested.
- One task at a time; stop at the review gate.
- **`ai_instructions.md` is binding** — plan first, wait for confirmation, document
  every change, clean up temp artifacts, never run `git commit`/`push`.
- **Commenting (§2.B) — settled 2026-09-27:** applies to **new code only**.
  Existing architectural doc comments are left alone. See the ruling note in
  `ai_instructions.md`.

> 📌 **Active work:** the functionality/correctness effort is tracked in
> `FUNCTIONALITY_PHASES.md` (Phases 1–4). **Phases 1 and 2 are done** — the
> events calendar is date-aware, and connectivity now distinguishes "transport
> attached" from "internet actually works". Phase 3 (the dead controls) is next.
> Read that before starting anything here.

---

## Queue

### Tier 0 — free wins, no dependencies (do first)

| ID | Task | Status |
|----|------|--------|
| ~~PERF-1~~ | ~~Delete orphan `ecotrace.png`~~ — **RETRACTED, DO NOT DELETE.** It is `SRC` in `tools/regenerate_icons.py` (the master for the launcher-icon pipeline). Unbundled ≠ unused. | 🚫 retracted |
| **PERF-2** | Recompress `lib/assets/icons/ecotrace_icon.png` (913 KB / 1024²) — it *is* bundled, so this is the only asset work that moves the APK size. Use `pngquant`. | ⬜ |
| **PERF-3** | Hoist `EventsScreen._daysWithEvents` to a `static final` list | ⬜ |
| **D-1** | ~~Fix stale test count (`11/11` → `22`) in `PERFORMANCE_REPORT.md` and `PERFORMANCE_TRACKING.md`~~ — **DONE 2026-09-27.** Both now carry a correction note, and the tracking log records the 22 and 26 milestones. Historical rows left unedited on purpose so the audit trail stays honest. | ✅ done |
| **D-2** | ~~Doc sweep: stop older docs describing the superseded two-state connectivity design.~~ — **DONE 2026-09-27.** `PHASE_3_PROGRESS.md`, `PERFORMANCE_REPORT.md`, `PERFORMANCE_TRACKING.md` and `CODE_AUDIT_2026-09-27.md` all annotated. | ✅ done |
| **D-3** | ~~§2.B comment scope: does the minimal-comments rule apply to existing code?~~ — **SETTLED 2026-09-27, user ruled: new code only.** Ruling written into `ai_instructions.md` §2.B, the ground rules above, and `FUNCTIONALITY_PHASES.md` decision #5. Existing architectural doc comments are left untouched. | ✅ done |
| **D-4** | ~~Remove `AppDate.relativeLabel` — dead code I wrote in Phase 1 (one definition, zero callers).~~ **DONE 2026-09-27.** `scheduleHeading` is the only relative-label helper the app actually uses. | ✅ done |
| **V-1** | Persist completed verifications. Phase 3's record lives only in `MapScreen._verifiedStatuses` and is **lost on app restart**; there is no storage layer yet. Unblocks with the Tier 1 persistence keystone. | ⬜ highest value |
| **V-2** | Retire `ManualEntrySheet`. The scanner's old one-page form duplicates the new wizard and is strictly worse — it asks for a tree tag the officer already selected, has no evidence step and no proximity check. Route its button into the wizard, or delete it. | ⬜ |
| **V-3** | Live-fix the proximity gate. A single GPS sample widened by accuracy can accept a 6 m reading with a 20 m fix. Averaging several fixes would tighten the gate without stranding officers on the tree. | ⬜ |
| **V-4** | Review/reject path. Every record is written as `VerificationStatus.pending` and nothing ever moves it, so a submitted verification is inert. Needs the admin portal side. | ⬜ |
| **SEC-1** | Remove or guard the client-side `passwordHash` on `MonitoringStaff` (`auth/domain/monitoring_staff.dart:22`) — a device-side hash field violates the project's own data rules. ⚠️ **HOLD: that file has uncommitted local changes** | ⛔ hold |

### Tier 1 — persistence keystone (unblocks the most)

| ID | Task | Status |
|----|------|--------|
| **F-2a** | Pick + add a local-store dependency (`shared_preferences` for now; escalate to `sqflite` when record counts grow) | ⬜ |
| **F-2b** | Make **verification draft save** real (`manual_entry_sheet.dart` `_saveDraft` currently only SnackBars) | ⬜ |
| **F-2c** | Make **incident draft save** real (`incident_report_screen.dart` "Save incident draft") | ⬜ |
| **F-2d** | Persist **event participation** (`EventsScreen._joinedEvents` in-memory set) | ⬜ |
| **F-2e** | Add an offline queue so nothing is lost before the backend exists | ⬜ |

### Tier 2 — wire screens to the existing domain models

| ID | Task | Status |
|----|------|--------|
| **F-3a** | Incident form: replace `onChanged: (_) {}` stubs + `const TextField` with real controllers/validation | ⬜ |
| **F-3b** | Map incident form to the typed `IncidentReport` / `IncidentType` / `IncidentSeverity` enums (currently stringly-typed) | ⬜ |
| **F-3c** | Map manual verification form to the typed `TreeRecord` / `PlantStatus` / `MeasurementSource` (currently `String _plantStatus = 'Healthy'`) | ⬜ |
| **F-4** | Alerts `FilterTabs` actually filter the list (PERF-4: decorative today) | ⬜ |

### Tier 3 — architecture & state management

| ID | Task | Status |
|----|------|--------|
| **ARCH-1** | Choose one state-management approach (README asks for this; unchosen) and adopt it consistently | ⬜ |
| **ARCH-2** | Populate the `core/` structure the README targets: `routing/`, `errors/`, `network/`, `storage/`, `widgets/` | ⬜ |
| **ARCH-3** | Add unit tests for the domain models + aggregation (currently zero unit tests) | ⬜ |

### Tier 4 — backend-dependent (⛔ blocked)

| ID | Task | Status |
|----|------|--------|
| **F-1** | Real authentication: DTOs, data source, repository, secure token storage, session restore, expiry, route guard | ⛔ needs API contract |
| **F-5** | Real sync dashboard: transport, queue states, conflict UI, pull-to-refresh, last-sync time | ⛔ needs API contract |
| **F-8** | Map inventory from backend instead of the 23-tree local seed | ⛔ needs tree-records endpoint |
| **F-9** | Field-progress dashboard from a repository instead of preview data | ⛔ needs events endpoint |
| **F-7** | Profile bound to the signed-in staff record (currently literals) | ⛔ needs auth (F-1) |
| **F-11** | Real GPS (add `geolocator`; replace the hard-coded campus-center `LatLng`) | ⛔ needs permission UX decision |
| **F-12** | Photo evidence capture (add `image_picker`/camera) | ⛔ needs storage + upload decision |
| **F-4b** | Camera/QR + NFC scanning (add `mobile_scanner`/`nfc_manager`) | ⛔ needs product + permission decision |

### Tier 5 — release hardening

| ID | Task | Status |
|----|------|--------|
| **F-13a** | Release signing (currently `signingConfigs.getByName("debug")` in `build.gradle.kts`) | ⬜ |
| **F-13b** | ABI splits to cut the 19.3 MB APK (deferred from `PERFORMANCE_TRACKING.md` P3-5) | ⬜ |
| **F-13c** | Structured logging with no credentials/evidence leakage | ⬜ |
| **F-13d** | Integration tests: slow network, offline, permission denial, restart, duplicate submit, conflict | ⬜ |
| **F-13e** | Release AAB + deployment checklist | ⬜ |

### Open measurement

| ID | Task | Status |
|----|------|--------|
| **PERF-6** | **Device frame timings** — `flutter run --profile` + DevTools timeline (typing / mode toggle / tab switch / map pan) for the prior audit round. Never measured — no hardware was attached. | ⛔ needs a device |

### Deliberately not changing

- Map `didUpdateWidget` memoization, roam bounds, tile cache, per-marker `RepaintBoundary`, fade-only route transitions, connectivity debounce — keep (see `CODE_AUDIT_2026-09-27.md` §1.2).
- The bottom-nav centre action is now **"View field progress"** (not the scanner) per `DASHBOARD_PROGRESS.md`. Scanner is reachable via a map tree's "Start Verification". Confirm with the product owner, don't "fix" it.
- Uncommitted working-tree work (`monitoring_staff.dart` modified, untracked `.vscode/`) — left untouched by the audit.

---

## Progress log

| Date | Task | Change | Gates |
|------|------|--------|-------|
| 2026-09-27 | Audit | Full read of 56 `lib/` files + configs. Wrote `CODE_AUDIT_2026-09-27.md` and this plan. Re-ran baseline: analyze clean, **22/22** tests pass (docs said 11 — logged as D-1). No code changed yet. | `flutter analyze` ✅ · `flutter test` 22/22 ✅ |
| 2026-09-27 | PERF-1 | **Retracted before any change was made.** User questioned the delete; re-grepped the *whole* repo instead of only `lib/` and found `tools/regenerate_icons.py:24` uses it as `SRC`. No deletion performed. Audit + plan corrected; lesson recorded (absence from `pubspec.yaml` proves *unbundled*, not *unused*). | n/a — no code touched |
| 2026-09-27 | Phase 1 | Calendar is now date-aware. `LocalEvent` carries a real `DateTime`; new `core/date/app_date.dart` centralises all date math; new `field_event_seed.dart` generates the four activities relative to today; strip is a rolling window from today; full calendar is a real month grid with month navigation; all `'Sep …'` literals removed. Also fixed a header overflow the live count introduced on 320dp viewports. Details in `FUNCTIONALITY_PHASES.md`. | `flutter analyze` ✅ clean · `flutter test` **22/22** ✅ |
| 2026-09-27 | Phase 2 | Connectivity is now honest. `connectivity_plus` 7.3.1 has no reachability check, so a new `InternetProbe` performs a real short-timeout HTTP HEAD; `ConnectionStatus` gained `unreachable` and `online` now requires transport **and** a passing probe. Controller re-probes on every transport change and on a 30s heartbeat (so topping up data recovers the app without a reboot), and discards stale in-flight probes so a lost connection can't be resurrected. Banner and map header word the two failure states differently and the header takes the enum instead of a lossy `bool`. Mutation-tested the stale-probe guard. | `flutter analyze` ✅ clean · `flutter test` **26/26** ✅ |
| 2026-09-27 | Docs + D-4 | User challenged whether the work was actually documented. Grepped every `*.md` rather than trusting the two active files, and found real drift: four older docs still described the superseded two-state connectivity design and stale `11/11` counts. Repaired all of them (D-1, D-2), recorded the §2.B ruling (D-3), and removed the dead `AppDate.relativeLabel` I had written in Phase 1 but never called (D-4). Historical log rows were annotated, never rewritten. | `flutter analyze` ✅ clean · `flutter test` **26/26** ✅ |
| 2026-09-27 | Phase 3 (verification) | On-site tree verification. New `lib/features/field_verification/domain/` (record, proximity, draft, limits) plus a proximity gate → mode choice → 4-step wizard, and the evidence/step-rail widgets. Verification cannot start unless the officer is within 5 m of the plant (widened by GPS accuracy, capped at 30 m). "Start Verification" now routes there; the tag scanner moved to a map-chrome button since it *finds* trees rather than verifying them. Added `geolocator` + `image_picker` and the location/camera manifest permissions. Three real bugs fixed: a units bug that made every measurement un-submittable, a missing-plant skip that disabled Continue, and a `copyWith` that could not clear a field. Added §2.D (test honesty) to `ai_instructions.md` after a test caught the units bug. Known gaps logged as V-1…V-4. | `flutter analyze` ✅ clean · `flutter test` **57/57** ✅ |

<!-- Append new rows below this line. -->
