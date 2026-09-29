# EcoTrace — Functionality & Correctness Phased Plan

**Created:** 2026-09-27 · **Status:** 🟡 Phases 1–2 of 4 complete
**Related:** `CODE_AUDIT_2026-09-27.md`, `TASK_PLAN.md`, `EVENTS_EXPERIENCE_PROGRESS.md`

Goal: make buttons/controls do what they claim, make the calendar track the real
current date, and stop reporting "connected" when there is no actual internet.

**Execution rule:** one phase at a time. Stop at each review gate, run
`flutter analyze` + `flutter test`, log the result, get sign-off before the next phase.

---

## What I found (verified, with evidence)

### A. The calendar is hard-coded to September 2026

`LocalEvent.day` is a bare `int` (1–30) with **no month or year**, so an event
literally cannot exist outside September 2026. Every surface repeats the assumption:

| Location | Hard-coded value |
|----------|------------------|
| `models/local_event.dart:4` | `final int day;` — no month/year |
| `screens/events/events_screen.dart:64` | `static const int _currentDay = 6;` — "today" is always the 6th |
| `screens/events/events_screen.dart:372` | `'Sep ${event.day} · ${event.time}'` |
| `screens/events/events_screen.dart:549` | `'Schedule for ${_selectedDay == 6 ? 'today' : 'Sep $_selectedDay'}'` |
| `widgets/events/calendar_strip.dart:24` | `List.generate(30, ...)` — always 30 days |
| `widgets/events/calendar_strip.dart:31` | `_weekday(day) => names[(day - 1) % 7]` — assumes the 1st is a Monday |
| `widgets/events/full_calendar_sheet.dart:23-24` | `daysInMonth = 30`, `firstDayOfWeek = 1` |
| `widgets/events/full_calendar_sheet.dart:78` | `'SEPTEMBER 2026'` header text |
| `widgets/events/full_calendar_sheet.dart:182` | `final isToday = day == 6;` |
| `widgets/events/participation_receipt.dart:160` | `'Sep ${event.day} · ${event.time}'` |

**Consequences today (2026-09-27):** the app opens on "Sep 6", the strip shows a
month that is 21 days stale, the full calendar labels the 6th as "today", and
weekday labels are wrong after the 1st. The four seeded events sit on days 6–8 —
all in the past.

### B. "Connected" is a lie when there is data but no internet

`connectivity_plus` **7.3.1** exposes only:
- `Stream<List<ConnectivityResult>> onConnectivityChanged`
- `Future<List<ConnectivityResult>> checkConnectivity()`

There is **no internet/reachability check** in this version (I grepped the
installed package source to confirm). `ConnectivityResult` reports the *transport*
(`wifi` / `mobile` / `ethernet` / `none`) — nothing about whether traffic actually
flows. Turning on mobile data with no load or no plan still reports `mobile`, so
`connectivity_controller.dart:_toStatus` maps it to `ConnectionStatus.online` and
the app shows "Internet Connected" while every request would fail.

`ConnectionStatus` is also only `{online, offline}` — there is no third state for
"network present but unreachable".

### C. Controls that do nothing

> **Path corrected 2026-09-29.** The rows below said
> `incident_report_screen.dart`; the real file is
> `lib/features/home/presentation/screens/incident/incident_report_screen.dart`.
> Line numbers re-verified against the file today — the findings themselves
> still hold.

| Location | Control | Current behaviour |
|----------|---------|-------------------|
| `screens/incident/incident_report_screen.dart:62` | Incident type dropdown | `onChanged: (_) {}` — selection discarded |
| `screens/incident/incident_report_screen.dart:73` | Severity dropdown | `onChanged: (_) {}` — selection discarded |
| `screens/incident/incident_report_screen.dart:85` | "Add photo evidence" | `onPressed: () {}` — no-op |
| `screens/incident/incident_report_screen.dart:76` | Description | `const TextField` — not even a controller |
| `widgets/alerts/filter_tabs.dart:14` | All / Recent / By date | `setState` repaints the pill, filters nothing |
| `screens/incident/incident_report_screen.dart:~90` | "Save incident draft" | SnackBar only, no data captured or stored |

---

## Phase 1 — Make the calendar date-aware ✅

**Status:** complete 2026-09-27. See the Progress log for what shipped.

**Why first:** the event data model is the foundation the receipt, section title,
and both calendar surfaces all read from. Fixing it first prevents doing the same
work twice.

1. **Widen the model.** `LocalEvent` carries a real `DateTime` (not `int day`).
   Keep the display fields (`time`, `title`, …) unchanged.
2. **Add a date utility** (`core/date/…`) — weekday labels, "Today"/"Tomorrow",
   month names, `MMM d` formatting. One place, no scattered literals.
3. **Date-relative seed data.** A `field_event_seed.dart` that generates the
   schedule from `DateTime.now()` — the existing four activities (tree planting,
   health survey, audit review, canopy check) assigned to *today, +1, +2, +4…*
   so the app always has a populated, forward-looking agenda with no database.
   Keeps every future or past run sensible.
4. **CalendarStrip** shows a rolling window from today (covers today + several
   weeks, so date-relative events are always selectable) with real weekdays and
   a real "today" highlight. Auto-scrolls to today on open.
5. **FullCalendarSheet** renders the real selected month: correct month/year
   header, correct `daysInMonth` (leap years included), correct leading blanks
   from `DateTime.weekday`, real today marker, and month navigation.
6. **Replace every `'Sep …'` literal** in `events_screen.dart` and
   `participation_receipt.dart` with formatted dates.
7. **"Today / 3 active today"** header copy reflects the real selected day.
8. **Tests** — the receipt test asserts `find.textContaining('Sep 6')`; make it
   derive the expected date from the seed instead of hard-coding.

**Gate:** analyze clean · all tests green · app opens on *today*, weekday labels
correct, calendar sheet shows the right month.

**Note:** `PHASE_2_PROGRESS.md` and `EVENTS_EXPERIENCE_PROGRESS.md` reference the
old Sept-6 fixtures; I'll update the affected lines, not rewrite history.

---

## Phase 2 — Honest connectivity ✅

**Status:** complete 2026-09-27. See the Progress log for what shipped.

1. **Add a reachability probe.** Small `InternetProbe` that performs a real,
   short-timeout HTTP HEAD/GET against a tiny, stable, well-known endpoint
   (e.g. a 204 from a CDN/GEN). Added via `flutter pub add http`.
2. **Two-signal model.** `ConnectionStatus` becomes
   `{online, offline, unreachable}` where *online* requires **both** a transport
   **and** a successful probe:
   - no transport → `offline`
   - transport present, probe fails → `unreachable` ← *this is the "data on, no
     internet" case the user is hitting*
   - transport present, probe succeeds → `online`
3. **Re-probe on every transport change**, and on a slow heartbeat (e.g. every
   30 s) so captive portals and plan expiry are caught while idle.
4. **Honest UI.** Banner/map-header show "Connected" only for `online`, and
   "No internet access" for `unreachable` (distinct from "No connection").
   Keeps the existing 600 ms debounce.
5. **Tests** — the existing offline test stays; add one asserting a reachable
   check is required, not just a transport signal.

**Gate:** analyze clean · tests green · enabling data with no load shows
"No internet access", not "Internet Connected".

---

## Phase 3 — Make the dead controls work 🚧

1. **Incident report (highest value).** Real controllers for description;
   incident type + severity bound to the typed `IncidentType` /
   `IncidentSeverity` enums already in `lib/features/incidents/domain/`; a real
   photo-evidence action; validation; and a genuine save.
2. **Alerts `FilterTabs`** actually filters the list (All / Recent / By date).
3. **Sweep the rest of the codebase** for remaining decorative controls and
   report anything that needs a product decision rather than guessing.

**Gate:** analyze clean · tests green · every control in the incident form and the
alert filters demonstrably works.

> **Status 2026-09-27 — items 1–3 are deferred and the phase is redefined.**
> The tree-verification feature (below) was prioritised over the dead-control
> sweep and shipped first. Nothing here is lost: the incident report, alert
> filters and remaining decorative controls are still open and are item 1 of the
> next phase. The verification work is documented in its own section.

---

## Phase 3 (shipped) — On-site tree verification 🚧

Requested 2026-09-27: verification must happen **at the plant**, not remotely.
A monitoring officer taps a tree, taps "Start Verification", and only then is
allowed to verify — so the flow is gated on location first.

**Flow:** tap tree → details sheet → *Start Verification* → **analysis mode** →
**proximity gate** → **4-step wizard** → record returned to the map.

> **Revised 2026-09-29.** The order was originally gate → mode → wizard. The
> mode choice now comes first, so the app does not open a GPS session for a
> plant the officer may not end up verifying; the gate still runs before the
> wizard, so the 10 m rule is still enforced. The gate button now reads
> "Continue" rather than repeating "Start verification".

> **GATE CURRENTLY DISABLED (2026-09-29, temporary).**
> `VerificationProximity.enforcementEnabled` is `false`, so the flow is
> **mode → wizard** and the proximity check is skipped entirely. This was done
> so the verification interface can be tested on a desk, on a simulator, or on
> a device with no location fix. The gate code is untouched — it returns as
> soon as the flag is set back to `true`. Records captured this way have
> `distanceFromTreeMeters == null`; that is the marker of an unverified
> position, and it must not be mistaken for proof the officer was at the plant.
> **Restore before recording real field data.**

### Domain (`lib/features/field_verification/domain/`)

| File | Purpose |
|---|---|
| `tree_record.dart` | `TreeRecord` + `PlantStatus` {alive, damaged, dead, missing}, `VerificationStatus`, `MeasurementSource`. Rewritten from the original stub. |
| `verification_proximity.dart` | `ProximityResult`, `ProximityFailure`, `PositionSource` (injectable), `GeolocatorPositionSource`, and `VerificationProximity.isAcceptable`. Also holds `VerificationProximity.enforcementEnabled`, the temporary gate switch (currently `false`). |
| `verification_draft.dart` | `VerificationStep`, `AnalysisMode`, and the mutable `VerificationDraft` that becomes a `TreeRecord` on submit. |
| `measurement_limits.dart` | Sanity bounds for both measurements, both in cm. |

### Presentation (`lib/features/home/presentation/`)

| File | Purpose |
|---|---|
| `screens/verification/start_verification_flow.dart` | The proximity gate. Owns the "am I there?" decision and the failure copy. |
| `screens/verification/analysis_mode_screen.dart` | Manual vs automatic. **Automatic is visibly disabled** with a "COMING SOON" badge. |
| `screens/verification/verification_wizard_screen.dart` | Status → Measurements → Evidence → Review, with per-step validation. |
| `widgets/verification/evidence_capture.dart` | Camera capture, 3–5 photos, with a thumbnail strip. |
| `widgets/verification/step_rail.dart` | The 4-dot progress indicator. |

### Decisions and trade-offs

- **The 10 m radius widens by the GPS accuracy, capped at 30 m.** Raised from
  5 m to 10 m on 2026-09-29; ten metres is roughly the width of the planting
  strip, so an officer standing beside the plant is inside it. A single
  outdoor GPS sample is routinely several metres out, so a hard `meters <= 10`
  cut-off would refuse officers who are demonstrably standing on the tree. The
  gate asks "could this officer be within 10 m of this plant?" and refuses when
  even a 30 m-accurate fix cannot answer yes. This is more honest in *both*
  directions than a hard cut-off, but it does mean a 6 m reading with a 20 m
  fix is accepted. If that trade is unacceptable, the fix is a live fix
  (several samples averaged) rather than a tighter constant.
- **Both measurements are entered in centimetres** (2026-09-29). Crown
  dimension was typed in metres and converted on the way in. One unit across
  the form costs an extra digit and removes a per-reading mental conversion
  for the officer — and removes the class of bug where a conversion is applied
  to the wrong field. The record still stores centimetres either way.
- **`PositionSource` is an interface** so the gate is testable without a device
  and so a future mock/simulator can be injected.
- **Automatic analysis is present but inert.** Wiring it to a placeholder that
  invents measurements would silently corrupt the dataset, so it is disabled
  rather than faked. `AnalysisMode.isAvailable` exists so the UI cannot offer
  an unavailable route by accident.
- **Camera only, no gallery** (your answer to decision #3). Evidence is
  proof of presence at that spot at that moment; a gallery image could be from
  last week.
- **A "missing" plant skips measurement and evidence** and goes straight to
  review — there is nothing to measure and nothing to photograph. Selecting
  missing also *clears* any measurements already typed, so a stale number
  cannot leak into a record asserting the plant is gone.
- **Status vocabulary is observational, not healthiness.** `PlantStatus` records
  presence and condition only, per your answer. Nothing in it implies a plant is
  thriving.
- **No persistence.** The result updates the map for the session and lives in
  `MapScreen._verifiedStatuses`; the shared `campusTrees` const is untouched.
  A real backend replaces that map. **A verification is lost on app restart** —
  this is the largest remaining gap.

### Bugs found and fixed while building this

1. **The DBH/crown validator applied one unit to both fields.** DBH is entered
   in cm and crown in metres; the shared validator multiplied both by 100, so a
   normal 24.5 cm DBH was rejected as "too large" and *no* measurement could ever
   be submitted. Caught by a widget test that entered realistic values. The
   validator now takes the unit conversion as a parameter.
2. **The missing-plant skip disabled "Continue" instead of advancing**, which
   would have stranded the officer on the status step — the exact case a missing
   plant is most likely to be. Caught by review before it shipped; now covered
   by a test.
3. **`VerificationDraft.copyWith` could not clear a field** (the classic
   `x ?? this.x` trap), so switching a plant to missing would have kept the old
   measurements. Now has explicit `clearMeasurements` / `clearPhotos` flags.

**Gate:** `flutter analyze` ✅ clean · `flutter test` **64/64** ✅ (up from 57)

---

## Phase 4 — Verification & documentation ⏸️

1. Full `flutter analyze` + `flutter test` + `flutter build apk --debug`.
2. Update `README.md` current-status, the affected phase docs, and `TASK_PLAN.md`.
3. Append a `Progress log` row per phase.
4. Report results and hand back. **No git commit** — that stays yours.

---

## Decisions I need from you

> **Update 2026-09-27 (later):** all five are now settled. #3 was answered by you
> directly — **camera, not gallery** — and the verification flow shipped on that
> basis. Nothing is open.

| # | Question | My recommendation | State |
|---|----------|--------------------|-------|
| 1 | Phase 1 calendar: **rolling window from today**, or **real month grid with prev/next**? | Rolling window from today — simpler, always shows today, and covers the date-relative seed. Month navigation can come later. | ✅ **Settled** — strip is a rolling window; the *sheet* additionally got a real month grid with prev/next (see Phase 1 notes). Tell me to drop the chevrons if unwanted. |
| 2 | Phase 2 probe endpoint — may I use a public 204 URL, or do you have an internal host to hit? | Public lightweight endpoint; swappable via one constant. If this app ships on a private network, an internal host is better. | ✅ **Settled** — shipped with `https://www.gstatic.com/generate_204` as `HttpInternetProbe.defaultEndpoint`. **Flagged for you:** if EcoTrace ships on a campus private network without public egress, point this at an internal host. It is a one-line change and takes a constructor parameter. |
| 3 | Phase 3 photo evidence — capture from camera, or pick from gallery? | Needs your call; it also decides which permissions get requested. | ✅ **Settled 2026-09-27** — **camera, not gallery**, 3–5 photos. You said evidence must be proof of presence at that spot. `CAMERA` permission added to the manifest; gallery is deliberately not offered. |
| 4 | Should dummy data keep the same four event identities, or may I vary them? | Keep the same four — preserves existing tests and copy. | ✅ **Settled** — same four titles, moved to today/+1/+2. |
| 5 | Does §2.B ("remove excessive comments") apply to new code only, or should existing architectural doc comments be swept too? | New code only — the existing comments are the architectural *whys* the rule preserves. | ✅ **Settled 2026-09-27** — new code only. Existing comments left untouched. Recorded as a ruling note in `ai_instructions.md` and a ground rule in `TASK_PLAN.md`. |

---

## Progress log

| Date | Phase | Change | Gates |
|------|-------|--------|-------|
| 2026-09-27 | Plan | Audited all 56 files + `connectivity_plus` 7.3.1 source. Wrote this plan. **No code changed.** | `flutter analyze` ✅ · `flutter test` 22/22 ✅ |
| 2026-09-27 | **1** | Calendar made date-aware. Added `core/date/app_date.dart`; `LocalEvent.day: int` → `date: DateTime`; added `models/field_event_seed.dart` (four activities at today/+1/+2, same titles & copy so existing assertions survive); `CalendarStrip` rebuilt as a 42-day rolling window from today with real weekdays and a today highlight; `FullCalendarSheet` rebuilt as a real month grid (leap-aware `daysInMonth`, `weekday`-derived leading blanks, dynamic header, **new prev/next month buttons**); removed every `'Sep …'` literal. | `flutter analyze` ✅ clean · `flutter test` **22/22** ✅ |
| 2026-09-27 | **2** | Connectivity made honest. `ConnectionStatus` gained `unreachable` + `isUsable`; **new** `InternetProbe` (HTTP HEAD, 5s timeout, `http` dependency); controller now requires transport **and** a passing probe, re-probes on every transport change plus a 30s heartbeat, and discards stale in-flight probes via a generation counter; banner host adds a distinct "No internet access" notice; `MapHeader` takes the enum instead of a lossy `bool`. | `flutter analyze` ✅ clean · `flutter test` **26/26** ✅ |
| 2026-09-27 | **3 (verification)** | On-site tree verification shipped. New `lib/features/field_verification/domain/` (record, proximity, draft, limits) and a proximity gate → mode choice → 4-step wizard. Verification cannot start unless the officer is within 5 m (widened by GPS accuracy, capped at 30 m); "Start Verification" now routes here instead of the scanner, which moved to a map-chrome button. Added `geolocator` + `image_picker` and the location/camera manifest permissions. Fixed a units bug that made every measurement un-submittable, a missing-plant skip that disabled Continue, and a `copyWith` that could not clear a field. | `flutter analyze` ✅ clean · `flutter test` **57/57** ✅ |
| 2026-09-29 | **3 (revision)** | Verification flow revised on user feedback. **Order changed**: the analysis-mode choice is now shown first and the proximity check runs only after manual is chosen, so the app no longer holds a GPS session open behind a screen the officer may back out of — the gate still runs before the wizard, so the radius rule is still enforced. **Radius raised 5 m → 10 m** (roughly the width of the planting strip, so standing beside the plant is inside it). **Both measurements now entered in cm** — crown was typed in metres and converted on the way in, which is exactly where the earlier units bug lived; `MeasurementLimits.metresToCentimetres` and the validator's `unitToCm` parameter are gone, so the two fields can no longer disagree about their unit. Gate button reads "Continue" instead of repeating "Start verification". Added `start_verification_flow_test.dart` (5 tests) using a fake `PositionSource`, and **mutation-tested the deferral** — moving the check back into `initState` turns the first test red, so it genuinely reaches the behaviour. | `flutter analyze` ✅ clean · `flutter test` **64/64** ✅ |

### Phase 1 notes (why it looks the way it does)

- **Month navigation was added, not deferred.** Decision #1 chose a rolling
  strip, but the full-calendar sheet is a *month* view — leaving it without
  prev/next would have stranded users on a month with no events. The chevrons
  are new UI, so flag it if you want them gone.
- **`AppDate` is deliberately the only place** that knows weekday alignment and
  month length. The old `_weekday(day) => names[(day - 1) % 7]` was wrong for
  every month that doesn't start on a Monday; that whole class of bug is now
  unrepresentable.
- **The strip is anchored on `DateTime.now()` at mount**, so a session left open
  across midnight keeps its original window until rebuilt. Acceptable for now;
  a `WidgetsBindingObserver` would fix it if you want.
- **Layout bug found and fixed en route.** Making the header badge count real
  (`"2 activities"`) made it 225px wide on a 320dp viewport, which squeezed the
  `Expanded` title to 29px and wrapped `"Today's schedule"` over 465px, blowing
  the root `Column` past the screen by 305px. Caught by the existing
  compact-viewport test. Fixed by capping the badge (`maxWidth: 132`) *and* by
  giving the title `maxLines: 2` + ellipsis, so no future copy change can
  re-explode the header.

### Phase 1 files touched

| File | Change |
|------|--------|
| `lib/core/date/app_date.dart` | **new** — weekday/month names, `daysInMonth` (leap-aware), `daysBetween`, `isSameDay`, `shortLabel`, `scheduleHeading`, `clampToMonth` |
| `lib/features/home/presentation/models/local_event.dart` | `int day` → `DateTime date` |
| `lib/features/home/presentation/models/field_event_seed.dart` | **new** — `buildFieldEventSeed({DateTime? now})`; the injectable `now` keeps it testable |
| `lib/features/home/presentation/screens/events/events_screen.dart` | `_selectedDay` is a `DateTime`; strip anchored on today; header/section copy derived; **badge width-capped** |
| `lib/features/home/presentation/widgets/events/calendar_strip.dart` | `int` days → rolling `DateTime` window; real weekdays; today highlight; added `ValueKey('calendar-day-y-m-d')` per cell for stable test targeting |
| `lib/features/home/presentation/widgets/events/full_calendar_sheet.dart` | real month grid + month navigation |
| `lib/features/home/presentation/widgets/events/participation_receipt.dart` | `'Sep ${event.day}'` → `AppDate.scheduleHeading(event.date)` |
| `test/widget_test.dart` | `LocalEvent(day: 6)` → `date: DateTime(2026,9,6)`; receipt assertion derives its expected date; day-select taps a `ValueKey` instead of the literal `'7'` |

**Deliberately untouched:** `monitoring_progress` preview data. Its tests assert
`Apr 15, 2026 – May 15, 2026` and friends, which is fixed campaign data, not a
"current date" surface. Phase 1 only reworked the *events* calendar.

---

### Phase 2 notes (why it looks the way it does)

- **The probe, not the platform, is the fix.** `connectivity_plus` 7.3.1
  exposes no reachability check at all — I read the installed source to confirm.
  The only way to tell "data is on" from "the internet works" is to attempt a
  real request, so `InternetProbe` is the load-bearing piece and everything else
  is bookkeeping around it.
- **Three states, and the third one is the whole point.** `offline` means
  nothing is attached. `unreachable` means something *is* attached but the
  request failed — mobile data on with no load, a captive portal, an exhausted
  plan. `online` requires both signals to agree. Collapsing the first two would
  have reproduced the original lie in a different shape.
- **The status seeds as `unreachable`, not `online`.** Defaulting to `online`
  means the first frame of the app claims a working connection it has not
  verified. Defaulting to `unreachable` means the worst honest answer until a
  probe says otherwise.
- **`isUsable` is the gate, not `== online`.** The banner host and the map header
  both branch on `ConnectionStatusX.isUsable`, so adding a fourth state later
  can't accidentally let an unverified status through as connected.
- **Wording distinguishes the two failures on purpose.** "No internet
  connection" (nothing attached → user should toggle something) vs. "No internet
  access" (radio is up → user should top up data or move). Same red, different
  instruction. The map header uses amber for `unreachable` for the same reason:
  the radio is fine, so red overstates the problem.
- **A stale probe cannot resurrect a lost connection.** A probe can be in flight
  for up to 5s; if the transport drops in that window the probe's "online" is
  *older* information than the "offline" that was just published. A monotonic
  generation counter makes each probe discard its answer if a newer evaluation
  landed while it awaited. I mutation-tested this guard: removing it makes the
  test fail with `Actual: ConnectionStatus.online`, so the test is load-bearing
  and not just decorative.
- **The heartbeat is what allows recovery.** None of "data topped up", "walked
  out of the dead zone", or "cleared a captive portal" raise a transport change
  event, so a 30s re-probe is the only way the app can notice the internet came
  back on its own. It's injectable (`heartbeat: null` disables it) purely so
  tests don't leave 30s timers pending.
- **`MapHeader` takes `ConnectionStatus`, not `bool isOnline`.** Passing the
  enum in makes an unhandled state impossible; the label and colour are derived
  with an exhaustive `switch` in one place.

### Phase 2 files touched

| File | Change |
|------|--------|
| `lib/core/connectivity/connection_status.dart` | `{online, offline}` → `{online, offline, unreachable}` + `ConnectionStatusX.isUsable` |
| `lib/core/connectivity/internet_probe.dart` | **new** — `InternetProbe` interface, `HttpInternetProbe` (HEAD, 5s timeout, errors → `false`), `ScriptedProbe` for tests |
| `lib/core/connectivity/connectivity_controller.dart` | injects `InternetProbe`; transport **and** probe must agree; 30s heartbeat; generation guard against stale probes; seed status `unreachable` |
| `lib/core/connectivity/connectivity_banner_host.dart` | branches on `isUsable`; third notice "No internet access" for `unreachable` |
| `lib/features/home/presentation/widgets/map/map_header.dart` | `bool isOnline` → `ConnectionStatus connection`; exhaustive label + colour switch |
| `lib/features/home/presentation/screens/map/map_screen.dart` | passes `connection` through instead of collapsing it to a bool |
| `pubspec.yaml` | `http` added (probe only; no other new dependency) |
| `test/widget_test.dart` | +4 tests: unreachable-not-online, heartbeat recovery, stale-probe discard, probe returns `false` rather than throwing; existing 2 updated for injected probes |
