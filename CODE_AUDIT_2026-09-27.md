# EcoTrace — Code Audit (2026-09-27)

> **📌 This is a point-in-time snapshot. It has been partly superseded.**
> Two correctness bugs found after this audit were fixed by the phased
> functionality work tracked in `FUNCTIONALITY_PHASES.md`:
> - **Phase 1 ✅** — the events calendar was hard-coded to September 2026
>   (`LocalEvent.day` was a bare `int`; `_currentDay = 6`; `List.generate(30)`;
>   `'SEPTEMBER 2026'`; `'Sep ${event.day}'` in two places). Now a real
>   `DateTime` model driven by `core/date/app_date.dart` and a date-relative
>   seed. This audit never listed that bug.
> - **Phase 2 ✅** — the connectivity banner reported a connection that did not
>   exist, because `connectivity_plus` 7.3.1 reports only the attached
>   *transport*. Now requires a passing HTTP reachability probe too, with a
>   third `unreachable` state. This audit never listed that bug either.
>
> **Section 2's feature-gap list is still accurate** — the persistence, auth,
> sync, scanner and profile gaps are all still open. **D-1 is now done.** Current
> gates: `flutter analyze` clean, `flutter test` **64/64**.

**Scope:** performance, optimization, and feature-completeness audit of the whole
Flutter app in `C:\flutter_workspace\ecotrace`.
**Method:** static read of all 56 `lib/` Dart files, `pubspec.yaml`,
`analysis_options.yaml`, `AndroidManifest.xml`, `android/app/build.gradle.kts`,
the asset tree, and the existing progress docs. Baseline gates re-run today.

## Baseline gates (re-verified 2026-09-27)

| Gate | Result |
|------|--------|
| `flutter analyze` | ✅ No issues found (ran in 6.4s) |
| `flutter test` | ✅ All 22 tests passed *(at audit time; now 26)* |

> **Doc drift found (and now fixed):** `PERFORMANCE_TRACKING.md` and
> `PERFORMANCE_REPORT.md` both claimed `flutter test 11/11`. The real count was
> **22**. Logged as **D-1**; corrected 2026-09-27, and the suite is now **26**.

---

## 1. Performance

The previous audit round (`PERFORMANCE_TRACKING.md`) already landed the big wins:
the 24σ `BackdropFilter` is gone, the map tab is lazy-gated, the 4 MB icon decodes
at 320 px, and `MapCanvas` memoizes its map subtree. Those are the right
patterns and should be preserved. What remains is mostly **size/asset hygiene**
and a few **smaller per-build allocations**.

### 1.1 Verified remaining issues

| ID | Pri | Finding | Evidence | Cost |
|----|-----|---------|----------|------|
| **PERF-1** | — | ~~`ecotrace.png` is an orphan~~ — **RETRACTED, see below** | Initially reported as a 1.0 MB orphan. That was **wrong**: `tools/regenerate_icons.py:24` declares it as `SRC`, the master source for the whole Android launcher-icon pipeline. | **Keep the file.** No action. |
| **PERF-2** | P2 | `ecotrace_icon.png` is 913 KB / 1024×1024 and *is* bundled | It is the splash + auth-badge asset. Runtime decode is already bounded (`cacheWidth/Height: 320` — P1-2 ✅; 2× badge size — P1-3 ✅), so the decode spike is mitigated, but the raw bytes still ship in the APK. | Smaller APK; runtime already mitigated. Compress with `pngquant` (the tooling already exists in `tools/`). |
| **PERF-3** | P3 | `_daysWithEvents` rebuilds a `Set`→`List` on every `EventsScreen` build | `events_screen.dart:102` getter does `_events.map((e) => e.day).toSet().toList()`; it is read at both the calendar strip and inline at line 525. `setState` on scroll-collapse / day-select / query re-runs it. | Tiny (4 events) but free to hoist to a `static final`. |
| **PERF-4** | P3 | `FilterTabs` ("All / Recent / By date") is decorative | `filter_tabs.dart:14` — tapping calls `setState` to change the selected pill **but nothing filters the alert list below it**. | No perf cost; this is a *feature* gap (see F-7), not a perf one. |
| **PERF-5** | info | No release signing, no ABI splits | `build.gradle.kts` still uses `signingConfigs.getByName("debug")` for release; no `splits { abi }` block. | Release-readiness, not runtime. |
| **PERF-6** | info | `PERFORMANCE_REPORT.md` claims are unmeasured on device | No hardware was attached in either audit round; every "cost" is a code-path expectation. | See the verification note at the end. |

### 1.2 Already done well — keep

- `_LazyTab` active-gated map in `app_shell.dart` (startup no longer inflates `FlutterMap`).
- `MapCanvas.didUpdateWidget` memoization + `CameraConstraint.containCenter` + shared
  7-day `BuiltInMapCachingProvider` + per-marker `RepaintBoundary`.
- Auth-screen blur removal; sign-up field extraction; `_CanopyPainter` seed reduction.
- Static theme singleton; static search-text map in events; debounced connectivity.
- Fade-only route transitions; hoisted validators/border instances.

---

## 2. Feature gaps (what is *not* implemented)

The app is a **high-fidelity frontend shell**. Screens render and interactions
work locally, but there is **no backend, no persistence, and no real state
management**. Dependencies in `pubspec.yaml` are only: `flutter`, `cupertino_icons`,
`connectivity_plus`, `flutter_map`, `latlong2`, `http`. There is **no `dio`, no
`shared_preferences`/`sqflite`/`hive`, no `flutter_secure_storage`, no state
management (no `provider`/`riverpod`/`bloc`), no `camera`/`mobile_scanner`, no
`nfc_manager`, no `geolocator`, no `image_picker`**.

> **Updated 2026-09-27 (Phase 2).** `http` is now a dependency, used *only* by
> `lib/core/connectivity/internet_probe.dart` to answer "is the internet actually
> reachable" — a question `connectivity_plus` cannot answer, because it reports the
> attached transport rather than whether traffic flows. No HTTP data source,
> repository, or backend integration was added. See `FUNCTIONALITY_PHASES.md` →
> "Phase 2 notes".

### 2.1 The orphaned domain layer (biggest structural gap)

Typed domain models exist but **nothing constructs or consumes them**. Verified by
grep — the only matches for `TreeRecord`, `IncidentReport`, `SyncSummary`,
`MonitoringStaff`, `PlantStatus`, `SyncStatus` are their own declarations:

| Model | File | Used by UI? |
|-------|------|-------------|
| `MonitoringStaff` (has a `passwordHash` field!) | `auth/domain/monitoring_staff.dart` | ❌ never instantiated |
| `TreeRecord` (+`PlantStatus`/`VerificationStatus`/`MeasurementSource`) | `field_verification/domain/tree_record.dart` | ❌ never instantiated |
| `IncidentReport` (+`IncidentType`/`Severity`/`Status`) | `incidents/domain/incident_report.dart` | ❌ never instantiated |
| `SyncSummary`/`SyncStatus` | `synchronization/domain/sync_state.dart` | ❌ never instantiated |

The screens instead use **hard-coded strings and one-off `String` fields**, so the
"typed contracts" described in the README are decorative today. Examples:
`manual_entry_sheet.dart` uses `String _plantStatus = 'Healthy'` (not the
`PlantStatus` enum); `incident_report_screen.dart` uses `DropdownMenuItem(value:
'Damaged tree')` strings (not `IncidentType`).

> ⚠️ **Security note:** `MonitoringStaff` has a `passwordHash` field on a
> client-side model. Even unused, a domain object that invites a plaintext/hash
> password on-device is against the project's own data rules. Flag as **SEC-1**.

### 2.2 Per-feature gap list

| ID | Feature | Status | Evidence |
|----|---------|--------|----------|
| **F-1** | **Authentication** | 🟡 UI only | Valid submit shows a SnackBar; no hashing, no API, no token, no session, no route guard, no logout state. Profile "Sign out" just `popUntil(isFirst)`. |
| **F-2** | **Persistence / offline drafts** | ❌ none | `manual_entry_sheet._saveDraft` and `incident_report_screen` "Save draft" only `showSnackBar` + `pop`. No local DB. Field workers lose all data on app restart. |
| **F-3** | **Incident reporting** | 🟡 static form | `onChanged: (_) {}` on type + severity, `onPressed: () {}` on "Add photo evidence" — selections are **not captured**. Description is a `const TextField` (not even a controller). Nothing is validated or saved. |
| **F-4** | **Scanner (NFC/QR)** | ❌ mock only | `scanner_screen.dart` is a static viewfinder illustration; no camera/NFC dependency exists. Only "Enter tree details manually" does anything. |
| **F-5** | **Sync dashboard** | 🟡 hard-coded | `sync_dashboard_screen.dart` is entirely `const` literals ("All records synced", "Last sync: Today, 09:42 AM", fixed `SyncRecord`s). Refresh button just SnackBars. No queue, no conflict UI, no real `SyncState`. |
| **F-6** | **Alerts** | 🟡 static list | Three hard-coded `AlertCard`s, no filtering (see PERF-4), no backend, no unread state. |
| **F-7** | **Profile** | 🟡 static | "Monitoring Staff", "STAFF-00042", staff number "239038" are literals; not bound to the signed-in user. |
| **F-8** | **Map tree data** | 🟡 local seed | 23 trees transcribed from the admin portal into `campus_data.dart`; not fetched from a backend, statuses not pushed back. |
| **F-9** | **Field-progress dashboard** | 🟡 preview data | `monitoring_progress_preview.dart` is a static list; explicitly documented as "preview, not live". |
| **F-10** | **Events participation** | 🟡 in-memory only | `_joinedEvents` is a `Set<String>` in widget state; check-in/leave is lost on restart. (The *receipt UX* is fully built — see `EVENTS_EXPERIENCE_PROGRESS.md`.) |
| **F-11** | **Location / GPS** | ❌ none | No `geolocator`. "GPS ready" badge and the map GPS dot use a hard-coded campus-center `LatLng`; no real device position. |
| **F-12** | **Photo evidence** | ❌ none | Buttons exist (`Add photo evidence`, camera icon) but no `image_picker`/camera and no handler. |
| **F-13** | **Release hardening** | ❌ none | Debug signing, no ProGuard/minify, no structured logging, no CI, no integration tests, no unit tests for domain logic. |

### 2.3 Architectural gaps

- **No state management.** README says "choose one predictable approach" — still
  unchosen. All state is local `setState`. `core/` has only `connectivity/` and
  `theme/`; there is no `routing/`, `errors/`, `network/`, `storage/`, or `widgets/`
  despite the README's target structure.
- **The shell's centre action moved.** Per `DASHBOARD_PROGRESS.md`, the bottom-nav
  centre button is now **"View field progress"**, not the scanner. The scanner is
  reachable only from a map tree's "Start Verification". Worth confirming this
  matches current product intent.

---

## 3. Recommended priority (no rebuilds)

Highest-value, lowest-risk first. **F-2 (persistence) is the keystone** — F-3, F-5,
F-10 all need it, and the project's own rule is "never silently discard a local
field report."

1. **PERF-2** recompress `ecotrace_icon.png` (913 KB → target <100 KB) — the only
   asset size work that actually affects the APK.
2. **PERF-3** hoist `_daysWithEvents` to `static final` (free).
3. **D-1** ~~correct the stale `11/11` → `22` in the two perf docs.~~
   ✅ **Done 2026-09-27** — both perf docs now carry a correction note and the
   tracking log records the 22 and 26 milestones.
4. **SEC-1** remove/guard the `passwordHash` field on the client `MonitoringStaff`.
5. **F-2** add local persistence (e.g. `shared_preferences` now, `sqflite` later)
   and make draft-save real for verification + incident + event participation.
6. **F-3** wire the incident form to controllers + validation + the domain model
   (depends on F-2 for save).
7. Choose and adopt **state management** (needed before F-1/F-5 scale).
8. **F-1** auth against the real backend (blocked on the API contract).
9. **F-4/F-11/F-12** camera/NFC/GPS/photos (blocked on product + backend decisions).
10. **PERF-5/F-13** release signing, splits, logging, CI.

**Explicitly blocked / do not guess:** F-1, F-4, and the backend half of F-8/F-9
all need the confirmed API contract, schema, and authorization rules (per README
"Current Next Action"). The project rule is: *do not invent endpoints, credentials,
or OpenCV behavior — leave a marked adapter boundary.*

---

## 4. How to verify (once hardware is attached)

The two prior audit rounds never had a device, so no number here is measured. To
close that out (this is the one open item in `PERFORMANCE_TRACKING.md`):

```powershell
flutter run --profile
```

Then in DevTools **Performance → Flutter Performance → Frame chart** or the
**Timeline**, exercise: typing in the auth form, login↔sign-up toggle, tab switches,
map pan/zoom, satellite toggle, and the events scroll-collapse. Record build+raster
times; compare against the pre-fix baseline. Mark `PERFORMANCE_TRACKING.md`'s
"Phase 5 — device frame timings" row done with real numbers.

---

## 5. Doc-drift / housekeeping notes

- **D-1** `PERFORMANCE_REPORT.md` + `PERFORMANCE_TRACKING.md` say 11 tests; real = 22.
- **PERF-1 retracted.** A whole-file grep scoped to `lib/**/*.dart` + `pubspec.yaml`
  reported `lib/assets/icons/ecotrace.png` as an unreferenced orphan. It is in fact
  the `SRC` master for `tools/regenerate_icons.py`. **Lesson: an asset being absent
  from `pubspec.yaml` proves it is unbundled, not that it is unused — always grep
  the whole repo (including `tools/`) before calling an asset dead.**
- Uncommitted work present in the working tree: `lib/features/auth/domain/monitoring_staff.dart`
  (modified) and an untracked `.vscode/` folder. Left untouched by this audit.
