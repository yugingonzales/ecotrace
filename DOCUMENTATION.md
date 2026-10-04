# EcoTrace — Project Documentation

**Single source of truth.** This file replaces the ten documents it was merged
from (listed in [Provenance](#12-provenance)). Every claim here was re-verified
against the working tree on **2026-10-03** rather than copied forward, because
the merged sources contained stale test counts, superseded designs and one
retracted finding.

> **`ai_instructions.md` remains separate and binding.** It is the operational
> protocol that governs *how* work is done (plan first, no auto-commits, test
> honesty), not documentation about the project. `README.md` is kept as the
> conventional repo front door.

## Contents

1. [Product & design language](#1-product--design-language)
2. [Current status](#2-current-status)
3. [Architecture](#3-architecture)
4. [Feature reference](#4-feature-reference)
5. [Domain contracts](#5-domain-contracts)
6. [Performance](#6-performance)
7. [Open work queue](#7-open-work-queue)
8. [Limitations & blockers](#8-limitations--blockers)
9. [Settled decisions](#9-settled-decisions)
10. [Verification gates](#10-verification-gates)
11. [Progress log](#11-progress-log)
12. [Provenance](#12-provenance)

---

## 1. Product & design language

EcoTrace is a Flutter **Android-only** app for environmental tree monitoring,
third-party auditing, field verification, incident reporting and sync of audit
feedback. Do not add iOS, web or desktop flows unless explicitly requested.

### Reference design

| Source | Path | Used for |
|---|---|---|
| Web project | `C:/Users/USER/Desktop/adi/New folder` | `login.html`, `css/login.css`, `index.html`, `css/add.css`, `alerts.html`, `events.html`, `map.html` |
| Admin portal (authoritative inventory) | `C:/laragon/www/ecotrace_admin` | `src/lib/trees.ts` (tree inventory + statuses), `src/lib/site.ts` (zones, campus bounds, mapping helpers) |

The Flutter map transcribes the admin portal's data into
`lib/features/home/presentation/models/campus_data.dart`.

### Theme tokens

| Token | Value | Usage |
|---|---|---|
| Forest | `#0D382C` | Primary buttons, active tabs, brand surface |
| Deep forest | `#0B1F17` | App background, header contrast |
| Dark forest | `#0A2A20` | Header gradient/source colour |
| Lemon | `#FFD600` | Logo, scan actions, emphasis |
| Canvas | `#F4F7F5` | Form and page background |
| Field | `#FFFFFF` | Text inputs, clean content surfaces |
| Border | `#E1E8E3` | Input borders, separators |
| Muted | `#6B8277` | Helper text, secondary labels |
| Soft text | `#8EB3A0` | Dark-header supporting text |
| Error | `#C74545` | Validation, destructive status |

Preserve this visual language: compact mobile screens, rounded controls, strong
dark-green contrast, lemon action accents, readable form spacing.

---

## 2. Current status

**Current gates: `flutter analyze` clean · `flutter test` 89/89 green.**

| Area | State |
|---|---|
| Entry point | `EcoTraceApp` launches into `SplashScreen`, which transitions to the staff login screen and then to `AppShell` on submit |
| Shell | Bottom nav with 5 slots; centre action is **"View field progress"**, not the scanner; dashboard actions remain in-shell and the dashboard profile icon is intentionally omitted |
| Events | Inline search (`events-search-field`), date-aware rolling strip and real month grid, collapsing strip, joined-only filter, right-aligned calendar action, multi-day start/end markers, participation receipt |
| Map | Real `flutter_map` campus map, 23 admin trees, OSM/Esri toggle, zone+status filters, left-rail controls, OSRM road routing |
| Verification | Mode choice → proximity gate → 4-step wizard (status, measurements, 3–5 camera photos, review) |
| Incidents | Linked-tree form with validated selections, description, camera evidence, draft save feedback |
| Alerts | Static list; tabs now genuinely filter |
| Profile | State-backed `UserProfile` with editable email, home address, contact number |
| Connectivity | Three-state model — `online` requires transport **and** a passing HTTP probe |
| Field progress | Theme-native dashboard with user quota, verified trees, event-wide target/progress/participant metrics, and a map handoff for verifying more trees |
| Sync dashboard | Static preview records with refresh feedback; transport remains pending |

### Test suite — 89 tests

| File | Tests |
|---|---|
| `test/widget_test.dart` | 31 |
| `test/features/field_verification/verification_test.dart` | 22 |
| `test/features/field_verification/verification_wizard_test.dart` | 9 |
| `test/features/field_verification/start_verification_flow_test.dart` | 6 |
| `test/features/monitoring_progress/monitoring_progress_test.dart` | 6 |
| `test/core/loading/loading_views_test.dart` | 9 |

### Dependencies

`cupertino_icons`, `connectivity_plus ^7.3.1`, `flutter_map ^8.3.2`,
`latlong2 ^0.10.1`, `http ^1.6.0`, `geolocator ^14.1.1`, `image_picker ^1.2.3`.

> **`http` is a probe-only dependency.** It is used *solely* by
> `lib/core/connectivity/internet_probe.dart` to answer "is the internet actually
> reachable". There is **no** HTTP data source, repository or backend
> integration anywhere in the app.

**Still absent by design:** no `dio`, no `shared_preferences`/`sqflite`/`hive`, no
`flutter_secure_storage`, no state management (`provider`/`riverpod`/`bloc`), no
`mobile_scanner`, no `nfc_manager`, no camera package (`image_picker` only).

**Android manifest permissions:** `INTERNET`, `ACCESS_NETWORK_STATE`,
`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`.

**Scale:** 69 Dart files in `lib/`.

---

## 3. Architecture

### Target structure

```text
lib/
  main.dart
  core/
    theme/  date/  connectivity/
    routing/  errors/  network/  storage/  widgets/     ← still to be populated
  features/
    auth/            data/ domain/ presentation/
    field_verification/  data/ domain/ presentation/
    incidents/       data/ domain/ presentation/
    synchronization/ data/ domain/ presentation/
    monitoring_progress/  data/ domain/ presentation/
    home/            presentation/
```

`core/` currently holds **only** `theme/`, `date/` and `connectivity/`. The
`routing/`, `errors/`, `network/`, `storage/` and `widgets/` targets are empty.

### Layering rules

- Widgets render and handle interaction only.
- Validation and business rules belong in domain/use-case code.
- HTTP, storage, camera, OpenCV and sync details stay **out** of presentation.
- Keep widgets focused; decouple business logic from framework routing.

### State management — still unchosen

All state is local `setState`. The README asks for one predictable approach and
it has never been selected. Required boundaries when it is:

- `AuthState`: signed out, submitting, authenticated, failure
- `FieldVerificationState`: draft, capturing, manual entry, submitting, submitted, failed
- `IncidentState`: draft, submitting, submitted, failed
- `SyncState`: online, offline, syncing, synced, conflict, failed

Avoid global mutable state; no API calls in screen widgets.

---

## 4. Feature reference

### 4.1 Authentication

`lib/features/auth/presentation/staff_auth_screen.dart` — login + staff sign-up,
staff ID, staff number, staff type, password, confirmation, local validation,
password visibility toggle.

**Presentation was rebuilt from scratch on 2026-10-02** while retaining the
existing controllers, validators, password visibility state, staff-type selector,
login/sign-up toggle, submit flow and `AppShell` replacement route. The heavy
animated glass canopy was replaced with a static repaint-bounded backdrop, a
responsive scrollable form, a constrained desktop width, lighter field/card
styling and keyboard-safe bottom padding. A compact 320 px overflow was fixed by
scaling the brand row to its available width.

> **The screen is in the launch path.** `EcoTraceApp` starts at `SplashScreen`;
> the splash plays its staged animation (see `kSplashSequenceDuration`) and
> transitions to this screen, which replaces itself with `AppShell` on submit.

### 4.2 Events

| File | Role |
|---|---|
| `screens/events/events_screen.dart` | Collapse controller, scroll listener, shared participation flow, confirmation dialog |
| `models/local_event.dart` | `LocalEvent` carrying a real `DateTime` |
| `models/field_event_seed.dart` | Four activities generated relative to today |
| `core/date/app_date.dart` | The **only** place that knows weekday alignment and month length |
| `widgets/events/calendar_strip.dart` | 42-day rolling window from today, real weekdays, today highlight |
| `widgets/events/full_calendar_sheet.dart` | Real month grid, leap-aware, prev/next navigation |
| `widgets/events/participation_receipt.dart` | Confirmation overlay, countdown bar, 3 s auto-dismissal |
| `widgets/events/event_card.dart`, `event_details_sheet.dart` | Card + details actions |

**Collapsing strip.** One-way per scroll direction: `pixels <= 8` always reveals;
downward travel past `28` collapses; any other upward scroll **stays collapsed**.
The two thresholds create a 20 px dead zone so the top overscroll bounce cannot
flicker the header. The 18 px gap above the strip lives *inside* the collapsed
child — as a sibling it never animated away and left 34 px of dead green.

**Participation flow.** `_requestParticipation` is shared by the card and the
details sheet so the two entry points cannot drift. Withdrawal is silent; joining
shows a confirmation dialog; **Not now** leaves participation unchanged with no
receipt; **Enter event** adds the event exactly once and shows the receipt.

**Receipt.** Pushed on the root navigator via `showGeneralDialog`, announced as a
live region (`Participation confirmed for <title>`), auto-dismisses after three
seconds (`kParticipationReceiptDuration`). Six bands: gradient header, event
title as hero (no `maxLines`, wraps freely), detail rows with a lemon time pill,
and an optional countdown bar. **There is no pass id, barcode or perforation** —
the ticket metaphor only ever carried a credential and nothing scanned it, so it
was a false affordance; removing it took the card from **332 px to 269 px**.

### 4.3 Map

| File | Role |
|---|---|
| `screens/map/map_screen.dart` | Chrome, state, OSRM routing, left-rail actions |
| `widgets/map/map_canvas.dart` | Tiles, zone halos, markers — memoized subtree |
| `widgets/map/map_header.dart` | Satellite toggle + live `ConnectionStatus` |
| `widgets/map/map_filter_panel.dart` | Zone pills + status tiles with live counts |
| `widgets/map/tree_details_card.dart` | Bottom sheet: `Start navigation`, `Clear route` |
| `widgets/map/gps_marker.dart` | Pulsing glow, **only while tracking** |
| `models/campus_data.dart` | 23 `TRE-*` trees, zones, bounds — transcribed from the admin portal |
| `models/map_tree.dart` | `TreeStatus {verified, pending, incident, unverified}` |

**Tree inventory:** 23 trees — 11 verified, 6 pending, 4 incident, 2 unverified.
Zone halo rectangles mirror the admin `framingBounds` padding. Attribution chips
read `© OpenStreetMap` / `© Esri`.

**Left-rail controls** (all actions live on the left): *Track my location*,
*Find nearby trees*, *Clear nearby* (only when a search is active), *Filters*,
*Recenter map*. The QR control was removed on 2026-10-02.

**Routing.** *Start navigation* requests an OSRM road route
(`router.project-osrm.org`) with an 8 s timeout, rendered as dotted segments. A
local campus corridor is drawn immediately as an optimistic path and **retained as
the offline fallback** when the request fails.

**Recent UI/UX work (2026-10-02).** Rectangular zone polygons were removed; the
pulsing GPS glow was gated to live tracking so an idle map settles cleanly (this
mattered for tests); the synthetic trace became the fallback rather than the
primary path.

### 4.4 Field verification

**Flow:** tap tree → details sheet → *Start Verification* → **analysis mode** →
**proximity gate** → **4-step wizard** → record returned to the map.

| File | Role |
|---|---|
| `field_verification/domain/tree_record.dart` | `TreeRecord`, `PlantStatus {alive, damaged, dead, missing}`, `VerificationStatus`, `MeasurementSource` |
| `field_verification/domain/verification_proximity.dart` | `ProximityResult`, `ProximityFailure`, `PositionSource` (injectable), `GeolocatorPositionSource`, `isAcceptable`, `enforcementEnabled` |
| `field_verification/domain/verification_draft.dart` | `VerificationStep`, `AnalysisMode`, mutable `VerificationDraft` |
| `field_verification/domain/measurement_limits.dart` | Sanity bounds, both in cm |
| `screens/verification/start_verification_flow.dart` | The gate; owns the "am I there?" decision |
| `screens/verification/analysis_mode_screen.dart` | Manual vs automatic (automatic disabled, "COMING SOON") |
| `screens/verification/verification_wizard_screen.dart` | Status → Measurements → Evidence → Review |
| `widgets/verification/evidence_capture.dart` | 3–5 camera photos + thumbnail strip |
| `widgets/verification/step_rail.dart` | 4-dot progress indicator |

> ⚠️ **PROXIMITY GATE IS CURRENTLY DISABLED.** `VerificationProximity.enforcementEnabled`
> is `false` (`verification_proximity.dart:110`), so the flow is **mode → wizard**
> and the check is skipped. This was done so the interface can be tested on a
> desk, simulator, or device with no fix. The gate code, the 10 m rule, the
> failure states and the retry path are untouched and return with one `true`.
> Records captured this way have `distanceFromTreeMeters == null` — that is the
> marker of an unverified position and must not be mistaken for proof the officer
> was at the plant. **Restore before recording real field data.**

**Design decisions.** The 10 m radius widens by GPS accuracy, capped at 30 m —
it asks "could this officer be within 10 m of this plant?" rather than imposing a
hard cut-off that would refuse officers demonstrably standing on the tree. Both
measurements are entered in **centimetres**, so the two fields cannot disagree
about their unit. `PositionSource` is an interface so the gate is testable
without a device. Automatic analysis is present but **inert** — wiring it to a
placeholder that invents measurements would silently corrupt the dataset, so
`AnalysisMode.isAvailable` keeps the route un-offered. Camera only, no gallery:
evidence must be proof of presence at that spot at that moment. A *missing* plant
skips measurement and evidence and **clears** any values already typed. Status
vocabulary is observational, not healthiness.

**No persistence.** Results live in `MapScreen._verifiedStatuses` and are **lost
on app restart**. The shared `campusTrees` const is untouched.

### 4.5 Incidents

`lib/features/home/presentation/screens/incident/incident_report_screen.dart`,
reached from a tree's detail sheet. The 2026-10-02 pass replaced no-op callbacks
with validated incident-type and severity selections, real description state,
camera evidence selection/removal, and saving feedback.

> **Still stringly-typed.** The form does **not** yet bind to the typed
> `IncidentReport` / `IncidentType` / `IncidentSeverity` enums in
> `lib/features/incidents/domain/`. Draft "save" is still SnackBar-level, not a
> real store. See **F-3a / F-3b**.

### 4.6 Alerts

Three `AlertCard`s over `models/alert_data.dart`. The All / Recent / By date tabs
**now actually filter** the rendered list (they were decorative until 2026-10-02).
Disabled search/filter header actions were removed.

### 4.7 Profile

State-backed `UserProfile` (`models/user_profile.dart`) with editable **Email**,
**Home Address** and **Contact Number**. Identity fields ("Monitoring Staff",
"STAFF-00042", staff number) remain **literals**, not bound to a signed-in user.

### 4.8 Connectivity

| File | Role |
|---|---|
| `core/connectivity/connection_status.dart` | `ConnectionStatus {online, offline, unreachable}` + `isUsable` |
| `core/connectivity/internet_probe.dart` | HTTP HEAD, 5 s timeout; default endpoint `https://www.gstatic.com/generate_204` |
| `core/connectivity/connectivity_controller.dart` | Single app-lifetime `ValueNotifier` |
| `core/connectivity/app_connectivity_scope.dart` | `InheritedNotifier` — only status readers rebuild |
| `core/connectivity/connectivity_banner_host.dart` | Global notice host via `MaterialApp.builder` |

**Why the probe exists.** `connectivity_plus` 7.3.1 reports only the attached
*transport* (`wifi`/`mobile`/`ethernet`/`none`). Turning on mobile data with no
load or no plan still reports `mobile`, so a transport-only model shows
"Internet Connected" while every request fails.

**Three-state model.** No transport → `offline`. Transport present, probe fails →
`unreachable` (the "data on, no internet" case). Transport **and** probe succeed
→ `online`. The controller re-probes on every transport change and on a **30 s
heartbeat** (so topping up data recovers the app without a reboot), and discards
stale in-flight probes via a generation counter so a lost connection cannot be
resurrected. The 600 ms debounce is kept. `MapHeader` takes the enum rather than
a lossy `bool`.

> **Deployment flag:** if EcoTrace ships on a private network without public
> egress, point `HttpInternetProbe.defaultEndpoint` at an internal host. One-line
> change, constructor parameter.

### 4.9 Field progress dashboard

| File | Role |
|---|---|
| `monitoring_progress/domain/monitoring_event_progress.dart` | `MonitoringEventProgress`, `MonitoringProgressSummary`, active-event aggregation |
| `monitoring_progress/data/monitoring_progress_preview.dart` | Static preview dataset |
| `monitoring_progress/presentation/monitoring_progress_screen.dart` | Forest header, progress hero, summary strip, cards |

Reached from the bottom-nav **centre** action, tooltip **"View field progress"**.

**Preview provenance.** Figures mirror the operational sample in the web admin
reference (`ecotrace_admin/src/components/modules/EventManagement.tsx`) and
exercise the aggregation rules — they are **not** live telemetry:

| Active event | Verified / target | Share |
|---|---|---|
| Arbor Day Drive 2026 | 1,680 / 2,250 | 75% |
| Coastal Mangrove Restoration | 515 / 1,250 | 41% |
| Campus Reforestation Q2 | 0 / 500 | 0% |
| **Active total** | **2,195 / 4,000** | **55%** |

The summary strip's **80 active staff**, **47 pending reviews** and **12 incidents**
derive from the same three active events. At least one completed event is present
**precisely so** active-only aggregation can be verified — completed work must not
leak into the headline numbers.

Aggregation tolerances: tracks clamp to 0–100% (over-target shows true counts and a
full track); zero/negative targets yield 0% instead of dividing by zero; negative
counters clamp to zero. Cards round independently of the summary, so a card can
read 75% while the active total is 55%.

### 4.10 Sync dashboard

`sync_dashboard_screen.dart` is entirely `const` literals — "All records synced",
"Last sync: Today, 09:42 AM", fixed `SyncRecord`s. Refresh SnackBars. No queue, no
conflict UI, no real `SyncState`.

### 4.11 Scanner

`scanner_screen.dart` is a static viewfinder illustration. No camera/NFC
dependency. The scanner moved out of the bottom nav (centre is now field
progress) but is still reachable from the map chrome. `ManualEntrySheet` remains
reachable from the tag scanner and is **strictly worse** than the wizard — see V-2.

---

## 5. Domain contracts

### `MONITORING_STAFF`

```text
staff_id       : unique identifier
staff_number   : login/business identifier
password_hash  : server-side password hash; never store plaintext
staff_type     : intern | paid volunteer | staff
```

Recommended future fields, pending backend confirmation: `display_name`,
`email`, `phone_number`, `active`, `created_at`, `updated_at`, `last_login_at`.

The client should receive a session/token response, **not** the password hash.

> ⚠️ **SEC-1 (hold).** `MonitoringStaff` carries a client-side `passwordHash`
> field (`auth/domain/monitoring_staff.dart:22`). Even unused, a domain object
> that invites a hash on-device violates the project's own data rules. **Blocked:**
> that file has uncommitted local changes.

### `TREE_RECORD`

```text
tree_id, tree_code/tag, species, latitude, longitude,
dbh, crown_dimension, plant_status, verification_status,
verified_by_staff_id, verified_at, photo_evidence, notes
```

Field names, units, enum values, required fields and server ownership must be
confirmed from the backend schema. DBH and crown dimension display units explicitly.

### Incident report

```text
incident_id, tree_id, reported_by_staff_id,
incident_type: damaged | missing | other,
severity, description, latitude, longitude,
photo_evidence, reported_at, status, sync_status
```

### The orphaned domain layer — **the biggest structural gap**

Typed models exist but **nothing constructs or consumes them**. Verified by grep —
the only matches for `TreeRecord`, `IncidentReport`, `SyncSummary`,
`MonitoringStaff`, `PlantStatus`, `SyncStatus` are their own declarations:

| Model | File | Constructed by UI? |
|---|---|---|
| `MonitoringStaff` (has `passwordHash`) | `auth/domain/monitoring_staff.dart` | ❌ never instantiated |
| `TreeRecord` (+ `PlantStatus`/`VerificationStatus`/`MeasurementSource`) | `field_verification/domain/tree_record.dart` | ✅ since the verification wizard |
| `IncidentReport` (+ `IncidentType`/`Severity`/`Status`) | `incidents/domain/incident_report.dart` | ❌ never instantiated |
| `SyncSummary` / `SyncStatus` | `synchronization/domain/sync_state.dart` | ❌ never instantiated |

The incident form and `manual_entry_sheet.dart` still use hard-coded strings and
one-off `String` fields, so those "typed contracts" remain decorative.

---

## 6. Performance

### 6.1 Landed

| ID | Finding | Fix | Status |
|---|---|---|---|
| P0-1 | 24σ `BackdropFilter` re-rasterized the whole auth card on every keystroke, focus change, mode toggle and keyboard frame | Removed `RepaintBoundary`/`ClipRRect`/`BackdropFilter` + `import 'dart:ui'`; card keeps its translucent fill, radius, border, shadow | ✅ |
| P0-2 | 200 ms keyboard glide animated the blur | Resolved by P0-1 — the animation stays, the blur is gone | 🚫 |
| P1-1 | Eager `IndexedStack` mounted the live `FlutterMap` (tiles + 23 markers) offstage on every tab | `_LazyTab` gates the map slot on `active` and caches the subtree after first visit | ✅ |
| P1-2 | 4 MB full-resolution icon decode on splash | `cacheWidth/Height: 320` | ✅ |
| P1-3 | 4 MB icon decode on auth badge | Decode at 2× badge size | ✅ |
| P2-1 | 166 AA circles painted at native res on first frame | Seeded counts 44→28, 16→10, 84→54, 22→14 | ✅ |
| P2-2 | Login/sign-up toggle rebuilt the entire ~500-line form | Sign-up blocks extracted to two methods; parent swaps single nodes | ✅ |
| P3-1 | Redundant outer `RepaintBoundary` per marker | Removed (marker self-boundaries remain) | ✅ |
| P3-2 | Per-build search-string recompute in `_visibleEvents` | `static final _searchText` map precomputed at class load | ✅ |
| P3-3 | Fresh `ThemeData` allocated per getter access | `static final light = _buildLight()` | ✅ |
| P3-4 | 96 KB tracked dead `.backup` | Deleted | ✅ |
| P3-5 | 892 KB bundled icon + 19.3 MB release APK, no ABI splits | Deferred | 🚫 |

**Learnings worth keeping.**

- **`IndexedStack` is eager in this Flutter version.** A probe test proved all
  four tab children (incl. `MapScreen`) inflate at `AppShell` startup and stay
  offstage, so lazy-through-`IndexedStack` needs an explicit `active` gate.
  Verified: `MapScreen` mounted **0** at startup → **1** after first Map tap →
  still **1** (offstage) after switching to Alerts.
- **A first `_LazyTab` draft was wrong** (a `_built` bool returning
  `SizedBox.shrink` after the first build) — it tore down the map element on the
  tab-switch rebuild and broke 5 widget tests. The `_cached ??=` form fixes it.
- **P2-2's** pre-username (names + staff type) and post-password (confirm)
  blocks are separated by the shared username/password fields, so they became
  two methods rather than one. Behaviour is unchanged — the diff is pure extraction.
- **P0-1** made `ImageFilter` unused, so `import 'dart:ui'` had to go too.

### 6.2 Preserve — do not "optimise" these

- `MapCanvas.didUpdateWidget` memoization + `CameraConstraint.containCenter` + shared 7-day `BuiltInMapCachingProvider` + per-marker `RepaintBoundary`.
- `containCenter` (not `contain`) keeps zoom-out unrestricted and never returns null, so the recenter button's `move(center, 16)` stays legal everywhere.
- One long-lived `NetworkTileProvider` shared by every `TileLayer` rebuild.
- Fade-only route transitions; hoisted validators/border instances; static theme singleton.
- Connectivity debounce; single app-lifetime subscription; `InheritedNotifier` scoping.
- Signs/sizes of the backdrop circle layers — only counts changed (P2-1).

### 6.3 Remaining

| ID | Pri | Finding | Action |
|---|---|---|---|
| **PERF-2** | P2 | `ecotrace_icon.png` is **892 KB / 1024²** and *is* bundled — the splash + auth-badge asset. Runtime decode is already bounded (`cacheWidth/Height: 320`, 2× badge), so only the shipped bytes remain. | `pngquant --strip` → target <100 KB |
| **PERF-3** | P3 | `EventsScreen._daysWithEvents` rebuilds a `Set`→`List` on every build; read at the strip and inline | Hoist to `static final` |
| **PERF-4** | — | Alert `FilterTabs` were decorative | ✅ **Fixed 2026-10-02** — now filters |
| **PERF-5** | info | Release uses `signingConfigs.getByName("debug")`; no `splits { abi }` | Release hardening |
| **PERF-6** | info | No device ever attached — every "cost" above is a code-path expectation | Needs hardware |

> **`lib/assets/icons/ecotrace.png` (987 KB) must NOT be deleted.** It was
> reported as an orphan and **that was wrong**: `tools/regenerate_icons.py:24`
> declares it as `SRC`, the master source for the entire Android launcher-icon
> pipeline. Absence from `pubspec.yaml` proves *unbundled*, not *unused*. This
> retraction is permanent — see §11, 2026-09-27.

### 6.4 How to verify on hardware

```powershell
flutter run --profile     # never take timings from a debug build
```

In DevTools → **Performance**, record a timeline while: (1) opening the keyboard
on the auth screen and typing, (2) toggling Login → Sign-up, (3) switching tabs
Events → Map and panning/zooming, (4) opening the tree details sheet. Watch the
Frame Chart (red = over the 16 ms budget) and the raster ("P") rows; enable
**Repaint Boundaries** to see which layers re-rasterize.

---

## 7. Open work queue

Priority order. **F-2 (persistence) is the keystone** — F-3, F-5, F-10 and V-1
all need it, and the project's own rule is "never silently discard a local field
report".

### Tier 0 — free wins, no dependencies

| ID | Task | Status |
|---|---|---|
| PERF-2 | Recompress `ecotrace_icon.png` (892 KB) with `pngquant` | ⬜ |
| PERF-3 | Hoist `EventsScreen._daysWithEvents` to `static final` | ⬜ |
| PERF-5 | Release signing + ABI splits | ⬜ |
| SEC-1 | Remove/guard the client-side `passwordHash` on `MonitoringStaff` | ⛔ **hold** — file has uncommitted changes |
| V-1 | **Persist completed verifications.** Phase 3's record lives only in `MapScreen._verifiedStatuses` and is lost on restart | ⬜ **highest value** |
| V-2 | **Retire `ManualEntrySheet`.** The scanner's old one-page form duplicates the wizard and is strictly worse — asks for a tree tag the officer already selected, no evidence step, no proximity check. Route its button into the wizard, or delete it | ⬜ |
| V-3 | **Live-fix the proximity gate.** A single GPS sample widened by accuracy can accept a 6 m reading with a 20 m fix. Averaging several fixes tightens the gate without stranding officers | ⬜ |
| V-4 | **Review/reject path.** Every record is written as `VerificationStatus.pending` and nothing ever moves it, so a submitted verification is inert. Needs the admin portal | ⛔ needs admin |

### Tier 1 — persistence keystone

| ID | Task | Status |
|---|---|---|
| F-2a | Pick + add a local-store dependency (`shared_preferences` now; escalate to `sqflite` when record counts grow) | ⬜ |
| F-2b | Make **verification draft save** real (`manual_entry_sheet._saveDraft` currently only SnackBars) | ⬜ |
| F-2c | Make **incident draft save** real | ⬜ |
| F-2d | Persist **event participation** (`EventsScreen._joinedEvents` is an in-memory `Set<String>`) | ⬜ |
| F-2e | Add an offline queue so nothing is lost before the backend exists | ⬜ |

### Tier 2 — wire screens to the domain models

| ID | Task | Status |
|---|---|---|
| F-3a | Incident form: real controllers/validation, replace remaining stubs | ⬜ |
| F-3b | Bind the incident form to `IncidentReport` / `IncidentType` / `IncidentSeverity` (currently stringly-typed) | ⬜ |
| F-4 | Alerts unread state / backend | ⬜ |

### Tier 3 — architecture & state management

| ID | Task | Status |
|---|---|---|
| ARCH-1 | Choose one state-management approach and adopt it consistently | ⬜ |
| ARCH-2 | Populate `core/`: `routing/`, `errors/`, `network/`, `storage/`, `widgets/` | ⬜ |
| ARCH-3 | Add unit tests for the domain models + aggregation | ⬜ |

### Tier 4 — backend-dependent ⛔

| ID | Task | Blocked on |
|---|---|---|
| F-1 | Real authentication: DTOs, data source, repository, secure token storage, session restore, expiry, route guard | API contract |
| F-5 | Real sync dashboard: transport, queue states, conflict UI, pull-to-refresh, last-sync time | API contract |
| F-7 | Profile bound to the signed-in staff record (currently literals) | F-1 |
| F-8 | Map inventory from backend instead of the 23-tree local seed | tree-records endpoint |
| F-9 | Field-progress dashboard from a repository instead of preview data | events endpoint |
| F-11 | Map "my location" marker + recentre-on-me (the recenter button still jumps to the hard-coded `campusCenterLat/Lng`) | partly done |
| F-12 | Incident form photo evidence (verification capture is done) | F-3a |

### Deliberately not changing

- The bottom-nav centre action is **"View field progress"**, not the scanner. Verification is reachable via a map tree's *Start Verification*. Confirm with the product owner — **don't "fix" it**.
- The map's memoization, roam bounds, tile cache, per-marker boundaries, fade-only transitions and connectivity debounce (see §6.2).
- `core/date/app_date.dart` is deliberately the single place that knows weekday alignment and month length — that whole class of bug is now unrepresentable.
- The calendar strip is anchored on `DateTime.now()` **at mount**, so a session left open across midnight keeps its window until rebuilt. Acceptable; a `WidgetsBindingObserver` would fix it.
- `lib/assets/icons/ecotrace.png` — **retracted deletion**, see §6.3.
- Uncommitted working-tree work — left untouched.

---

## 8. Limitations & blockers

### Intentional preview limitations

Authentication is not connected to a backend. A valid local form submission only
opens the frontend preview. No password is hashed, persisted, transmitted or
compared. No access token, refresh token, session or route guard exists. Profile
"Sign out" just `popUntil(isFirst)`.

### API contract must be confirmed first

Do not proceed with production auth until the API base URL, authentication
payload, response payload, token strategy, password-hashing responsibility, staff
ID format and authorization rules are agreed.

### Testing constraints discovered the hard way

- **`pumpAndSettle` waits out the participation receipt.** Because the receipt
  stays for three seconds, settling after confirming advances past the
  auto-dismissal and the receipt is gone before it can be asserted. These tests
  use bounded `pump` calls and pump `kParticipationReceiptDuration` explicitly.
- **Assertions must match what is actually on screen.** A list header that
  scrolls away is legitimately absent; event location text legitimately appears
  both in the dialog and on the card behind it — use `findsNothing`/`findsWidgets`.
- **Keep the GPS pulse gated to tracking.** An always-animating marker stops
  `pumpAndSettle` from ever settling and hangs tests.
- **Avoid `pumpAndSettle` near tile loading** — assert on marker codes and filter
  chips, not map tiles.
- **A green suite can hide a test that throws before its first assertion.** The
  map-header alignment test was committed having *never run green*: its
  `withInset` helper wrapped a bare `Scaffold` in a `MediaQuery` with no
  `MaterialApp`, so the build threw `No Directionality widget found` and failed
  at line 54. Always confirm a new test can go **red**.
- **Mutation-check meaningful tests.** Several fixes were verified by mutating
  the behaviour and confirming the suite turned red — the stale-probe guard, the
  proximity deferral, the header `topPadding` bound, the receipt-duration pump.
- **Raw-byte checks prove comment-only diffs.** The comment strip was verified by
  filtering `git diff` for non-`//` lines and confirming the result was empty.

### Known data-integrity caveats

- Verification records are **lost on restart** (`MapScreen._verifiedStatuses`).
- Event participation is **lost on restart** (`_joinedEvents`).
- The proximity gate is **disabled**; records made now have no position proof.
- `passwordHash` on a client-side model violates the project's own data rules.

---

## 9. Settled decisions

All questions previously raised are closed. Recorded so they are not re-litigated.

| # | Decision | Ruling |
|---|---|---|
| 1 | Calendar shape | **Rolling window** from today for the strip; the *sheet* additionally got a real month grid with prev/next (new UI — flag if unwanted) |
| 2 | Probe endpoint | `https://www.gstatic.com/generate_204` as `HttpInternetProbe.defaultEndpoint`. **Flagged:** point at an internal host if EcoTrace ships on a network without public egress |
| 3 | Photo evidence | **Camera, not gallery** — 3–5 photos. Evidence must be proof of presence at that spot; a gallery image could be from last week |
| 4 | Seed data | Keep the same four event identities/titles, moved relative to today |
| 5 | Comment rule (§2.B) | **New code only.** Existing architectural doc comments are the *whys* the rule preserves; do not sweep them |
| 6 | Verification order | **Mode choice → gate → wizard** (was gate → mode). No GPS session is opened behind a screen the officer may back out of |
| 7 | Proximity radius | **10 m**, widened by GPS accuracy, capped at 30 m |
| 8 | Measurement units | **Both in centimetres.** `MeasurementLimits.metresToCentimetres` and the validator's `unitToCm` parameter were removed so the two fields cannot disagree |
| 9 | Gate button copy | **"Continue"**, not a repeat of "Start verification" |
| 10 | Map control placement | All actions on the **left rail** |
| 11 | Header top margin | **2 dp**, centralized in `EcoTraceHeader.topPadding` (was 16, then 8, then 2 — it had been written out four times and drifted) |
| 12 | Launch flow | **Restore splash → login → shell** — `EcoTraceApp` starts at `SplashScreen`, which transitions to `StaffAuthScreen` and then to `AppShell` on submit. `kSplashSequenceDuration` is exposed so the launch test can outrun the animation instead of duplicating the timings |
| 13 | Bottom-nav centre | **"View field progress"** — confirm with the product owner, don't revert |

---

## 10. Verification gates

```powershell
cd C:\flutter_workspace\ecotrace
flutter pub get
flutter analyze      # must be clean
flutter test         # must be green — 71/71 at merge time
flutter build apk --debug
```

**Gate policy.** After every task: `flutter analyze` clean **and** `flutter test`
green. One task at a time; stop at the review gate. No `git commit` / `git push` —
version control stays under human control.

**Test-count discipline.** Historical rows in §11 record the count *at the time
each row was written*; they are left unedited so the audit trail stays honest.
The **live** count is the one in §2 — re-run `flutter test` rather than trusting a
number recorded in any log.

---

## 11. Progress log

| Date | Task | Change | Gates |
|---|---|---|---|
| 2026-09-27 | Audit | Full read of 56 `lib/` files + configs. Wrote the code audit and the task plan. Re-ran baseline: analyze clean, **22/22** tests (docs said 11 — logged as D-1). No code changed | analyze ✅ · 22/22 ✅ |
| 2026-09-27 | PERF-1 | **Retracted before any change was made.** User questioned the delete; re-grepped the *whole* repo instead of only `lib/` and found `tools/regenerate_icons.py:24` uses it as `SRC`. No deletion performed. Lesson recorded: absence from `pubspec.yaml` proves *unbundled*, not *unused* | n/a — no code touched |
| 2026-09-27 | Phase 1 | Calendar made date-aware. `LocalEvent.day: int` → `DateTime`; new `core/date/app_date.dart`; new `field_event_seed.dart` (four activities relative to today); strip rebuilt as a 42-day rolling window with real weekdays; full calendar rebuilt as a real leap-aware month grid with prev/next; every `'Sep …'` literal removed. Fixed a header overflow the live count introduced on 320 dp viewports | analyze ✅ · 22/22 ✅ |
| 2026-09-27 | Phase 2 | Connectivity made honest. `ConnectionStatus` gained `unreachable` + `isUsable`; new `InternetProbe` (HTTP HEAD, 5 s timeout, `http` dependency); controller requires transport **and** probe, re-probes on transport change plus a 30 s heartbeat, discards stale in-flight probes via a generation counter; banner adds a distinct "No internet access" notice; `MapHeader` takes the enum. Mutation-tested the stale-probe guard | analyze ✅ · 26/26 ✅ |
| 2026-09-27 | Docs + D-4 | User challenged whether the work was documented. Grepped every `*.md` rather than trusting the two active files and found real drift: four older docs still described the superseded two-state connectivity design and stale `11/11` counts. Repaired all of them, recorded the §2.B ruling (D-3), removed the dead `AppDate.relativeLabel` (D-4). Historical rows annotated, never rewritten | analyze ✅ · 26/26 ✅ |
| 2026-09-27 | Phase 3 (verification) | On-site tree verification. New `lib/features/field_verification/domain/` (record, proximity, draft, limits) plus mode choice → proximity gate → 4-step wizard and the evidence/step-rail widgets. "Start Verification" routes there; the tag scanner moved to a map-chrome button since it *finds* trees rather than verifying them. Added `geolocator` + `image_picker` and the location/camera permissions. Fixed three real bugs: a units bug that made **every** measurement un-submittable, a missing-plant skip that disabled Continue, and a `copyWith` that could not clear a field. Added §2.D test honesty after a test caught the units bug | analyze ✅ · 57/57 ✅ |
| 2026-09-29 | Phase 3 (revision) | **Order changed** — analysis mode first, proximity check only after manual is chosen, so no GPS session is held open behind a screen the officer may back out of; the gate still runs before the wizard. **Radius 5 m → 10 m.** **Both measurements in cm** — crown was typed in metres and converted on the way in, which is exactly where the earlier units bug lived. Gate button reads "Continue". New `start_verification_flow_test.dart` (5 tests) with a fake `PositionSource`; mutation-tested the deferral. Corrected a §C citation of a file path that does not exist | analyze ✅ · 64/64 ✅ |
| 2026-09-29 | Gate bypass (temporary) | `VerificationProximity.enforcementEnabled = false` so the interface can be tested without a fix. Gate code, the 10 m rule, failure states and retry path all untouched; return with one `true`. Kept **mutable** so the gate tests can still switch it on — a `const` flag would have forced deleting the only proof the gate works. Added a sixth bypass test, mutation-checked. **Records made this way have `distanceFromTreeMeters == null`; restore before real field use** | analyze ✅ · 65/65 ✅ |
| 2026-09-29 | Header spacing | Top margin of the Events, Alerts, Profile and field-progress headers reduced **16 → 8** (dashboard was already 12). `SafeArea` already supplies the ~24 dp status-bar inset, so 16 on top pushed content down until the status bar and title read as one oversized block. Value moved to one place, `EcoTraceHeader.topPadding`, because it was written out four times and had drifted. New test asserts all four resolve to the same value | analyze ✅ · 66/66 ✅ |
| 2026-09-29 | Header spacing (2nd pass) | Reduced again **8 → 2** on all four headers. A measured probe against `AlertsScreen` (0→8, 24→32, 28→36, 40→48) confirmed the gap is exactly the constant and `SafeArea` is applied once — on a real device the logo sat 40 px below the screen top and the status bar read as a separate band. The test bound tightened from `lessThan(16)` to `lessThanOrEqualTo(4)`; the old bound would have passed against the layout that caused the complaint. Probe file deleted | analyze ✅ · 66/66 ✅ |
| 2026-10-01 | Comment audit (§2.B) | Audited **all** 67 Dart files in `lib/` rather than sampling. Measured comment share at **7.9%** (556 `///` + 173 `//` of 9,212 lines) — already lean, so a blanket strip would have destroyed rationale, not noise. Kept every architectural *why*, removed only narration. **Those dividers also carried mojibake** — 64 sequences of `”` double-decoded, i.e. corrupted text sitting in committed source; byte-level inspection found them (the visible `â”€â”€` was *not* a real em-dash). All 64 gone. `test/` deliberately untouched — its 160 `//` lines record why assertions are shaped as they are | analyze ✅ · 67/67 ✅ |
| 2026-10-01 | Map header alignment (fixed) | The `every tab header, including the map, lines up with the rest` test was committed in `8bfadb1` but had **never run green** — its `withInset` helper wrapped a bare `Scaffold` in a `MediaQuery` with no `MaterialApp`, so the build threw `No Directionality widget found` and failed at line 54 before reaching a single assertion. A green suite had been masking it. Fixed the helper and mutation-checked: pinning the map header `+10px` produces `Expected: <24.0> Actual: <34.0>`, so the test genuinely bites | analyze ✅ · 67/67 ✅ |
| 2026-10-01 | Comment strip (done properly) | Removed **only** long comments across `lib/`: 108 multi-line blocks of ≥3 prose lines, 412 lines, 29 files. All **186** short (1–2 line) comments preserved. Verified three ways: analyze clean, 67/67 green, and a raw-byte check over `git diff` proving **0** changed lines are non-comment. Supersedes the earlier partial pass that wrongly removed short comments and briefly broke `app_date.dart`; that damage was reverted via `git checkout` | analyze ✅ · 67/67 ✅ |
| 2026-10-02 | Main-tab UI/UX overhaul | `EcoTraceApp` now launches directly into `AppShell`, skipping splash/login. Events use explicit `View details`, `Join activity`, `Join this activity` and `Confirm joining` actions with a flexible participant summary for compact screens. Map controls use labeled left-rail actions; route state exposes `Start navigation` and `Clear route`; the compact progress header scales its active badge. Updated launch, event, route and compact-layout tests | analyze ✅ · 70/70 ✅ |
| 2026-10-02 | Map controls and navigation refinement | Moved tracking, nearby, Filter, clear-results and recenter to the left rail with Filter below Nearby; changed Nearby to a tree icon distinct from GPS tracking; removed the rectangular zone polygon boxes; added a pulsing glow **only while live tracking is active** so idle tests and the idle map settle cleanly; replaced the synthetic trace as the primary path with OSRM road geometry rendered as dotted segments, retaining the local campus corridor as the offline fallback | analyze ✅ · 70/70 ✅ |
| 2026-10-02 | Global controls, profile, alerts and map | Removed disabled search/filter actions from Alerts and Profile headers; made Alert tabs filter the rendered alert list; added a state-backed `UserProfile` with editable Email, Home Address and Contact Number; replaced Incident Report no-op callbacks with validated selections, description state, camera evidence selection/removal and saving feedback; removed the map QR control; added Geolocator service/permission prompts, live position stream, heading-aware marker, nearby-tree count filtering/clear action and selectable-tree Direction or Trace action with keyed dotted local corridor rendering. Added focused widget tests for alerts, profile, QR removal/tracking replacement and route rendering | analyze ✅ · 70/70 ✅ |
| 2026-10-02 | Auth interface rebuild | Rebuilt `staff_auth_screen.dart` presentation from scratch while retaining controllers, validators, password visibility state, staff-type selector, login/sign-up toggle, submit flow and the `AppShell` replacement route. Replaced the heavy animated/glass canopy with a static repaint-bounded backdrop, responsive scrollable form, constrained desktop width, lighter field/card styling and keyboard-safe bottom padding. Fixed a compact 320 px overflow by scaling the brand row to its available width. No Flutter app was connected for hot reload; DTD discovery completed with no connected apps | analyze ✅ · 67/67 ✅ |
| 2026-10-03 | **Documentation consolidation** | Merged 10 documents into this file. Re-verified every load-bearing claim against the working tree instead of copying it forward: 70 tests (27+6+22+9+6) confirmed by per-file count, 69 Dart files in `lib/`, the 5 manifest permissions, `pubspec.yaml` dependencies, `enforcementEnabled == false` at `verification_proximity.dart:110`, `home: const AppShell()` in `main.dart`, and the three-state `ConnectionStatus`. Deleted the 10 merged sources; kept `README.md` and binding `ai_instructions.md`. Content that had gone stale was corrected rather than carried forward — see §12 | analyze ✅ · 70/70 ✅ |
| 2026-10-03 | Launch flow: login restored | `home:` in `main.dart` was still `AppShell`, a launch bypass that had been requested for the 2026-10-02 overhaul and committed there. The auth feature itself had never been deleted — `staff_auth_screen.dart` (688 lines) and the splash→login and login→shell routes were all intact, so the single line was the whole defect. Pointed `home:` back at `SplashScreen` and replaced the test that had locked the bypass in (`launches directly into the main application shell`) with two that assert the real chain: splash→login, and login→shell. Added `kSplashSequenceDuration` to the splash so the test outruns the staged 150+200+650+300+950 ms choreography from one named constant instead of a hardcoded guess, with an `assert` tying it to those delays. The stale `not in the launch path` / `splash/login bypassed` claims in §3 and §4.1 were corrected; the 2026-10-02 log row was left as the historical record | analyze ✅ · 71/71 ✅ |
| 2026-10-04 | Async feedback pass | Added shared Material 3 loading primitives (`EcoButtonLoader`, safe blocking overlay, determinate upload progress, and reduced-motion skeletons) with focused widget coverage. Wired authentication, camera evidence, incident saving, verification upload progress, GPS/proximity, OSRM routing, sync refresh, and pull-to-refresh flows for visible busy/error/completion feedback. Fixed the overlay to be safe in both `Stack` and normal body contexts. Re-verified the full suite at 88 tests and kept analysis clean | analyze ✅ · 88/88 ✅ |
| 2026-10-04 | Events interface update | Added the persistent keyed inline search field (`events-search-field`), moved the calendar action to the right side of the Events header, replaced the former filter action with the bottom-left **Joined activities** toggle, and added optional `LocalEvent.endDate` support. The full calendar now distinguishes activity starts with circular markers and activity ends with square markers, with a seeded multi-day event for validation. Updated widget coverage for inline search and keyed leave confirmation input | analyze ✅ · 89/89 ✅ |

---

## 12. Provenance

Merged on 2026-10-03 from these ten files, all deleted in the same change
(recoverable from git history):

| Merged file | Contribution |
|---|---|
| `README.md` | Product goal, reference design, theme tokens, architecture direction, domain contracts, planned phases |
| `TASK_PLAN.md` | The work queue, ground rules, progress log |
| `CODE_AUDIT_2026-09-27.md` | Full-repo audit, orphaned domain layer, per-feature gap list |
| `FUNCTIONALITY_PHASES.md` | Phases 1–2 (calendar, connectivity), Phase 3 verification design + bugs found |
| `PERFORMANCE_REPORT.md` | Performance findings P0–P3, applied fixes, hardware measurement guide |
| `PERFORMANCE_TRACKING.md` | Fix tracker with per-fix learnings and the "deliberately not changing" list |
| `DASHBOARD_PROGRESS.md` | Field-progress dashboard design + preview-data provenance |
| `EVENTS_EXPERIENCE_PROGRESS.md` | Collapsing calendar strip, participation flow, receipt design |
| `PHASE_1_PROGRESS.md` | Auth foundation |
| `PHASE_2_PROGRESS.md` | Frontend shell |
| `PHASE_3_PROGRESS.md` | Real interactive campus map, connectivity layer, map perf work |

> `README.md` and `ai_instructions.md` were **kept**, not merged.

### Content corrected during the merge, not carried forward

- **Test counts.** The sources variously claimed `11/11`, `22`, `26`, `64` and
  `67`. Only §2 is current; §11 rows are historical and deliberately unedited.
- **`ecotrace.png` as an "orphan".** Reported, then retracted — it is `SRC` in
  `tools/regenerate_icons.py`. Now a standing warning in §6.3 and §7.
- **Two-state connectivity.** Superseded by the three-state probe model; the old
  description survives only as history in §11.
- **`enforcementEnabled`.** Sources described the gate as enforced. It is
  `false` today; §4.4 leads with that warning.
- **"Phase 3 = dead controls".** Redefined and deferred; the dead-control sweep
  (incident form, alert filters) is still open and now tracked as F-3a/F-3b/F-4.
- **Icon size.** Stated as 913/914 KB; measured at **892 KB** today.
- **Dart file count.** Stated as 56 then 67; measured at **69** today.
- **`passwordHash`.** Kept as SEC-1 with its hold reason, not silently dropped.
- **The launch bypass, treated as settled.** The merge recorded `home: const
  AppShell()` as an intentional 2026-10-02 decision and stated in §4.1 that the
  login screen "is not in the launch path" — accurate, but it was a stale
  *fact* about a change whose intent was never re-confirmed. Verified as
  settled without asking. Corrected the same day: `home:` points back at
  `SplashScreen`, and §4.1 now describes the real chain. The lesson generalises —
  a documented state is not the same as an approved one, and a consolidated
  single source of truth launders an old decision into looking current.

---

*Maintained as the single source of truth. `ai_instructions.md` is binding.*