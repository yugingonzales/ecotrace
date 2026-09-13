# EcoTrace Phase 3 Progress: Real Interactive Campus Map

Phase 3 replaces the synthetic CustomPaint grid map with a real, interactive
Leaflet-style map driven by the admin portal's authoritative tree inventory.

## Completed

### Data port (admin portal → Flutter)

- `lib/features/home/presentation/models/map_tree.dart` reshaped around the
  admin portal's tree record:
  - `TreeStatus { verified, pending, incident, unverified }` with the admin
    portal labels and colors (`#2F9E6E`, `#D9902B`, `#DC3A3A`, `#9AA1A9`).
  - `MapTree` now carries `id`, real `lat`/`lng`, `status`, `planter`
    (admin `staffName`), `species`, `datePlanted`, and `zone`.
- New `lib/features/home/presentation/models/campus_data.dart` transcribed 1:1
  from the admin portal:
  - `campusZones` (Zone I / II / III centers, elevations, colors from `site.ts`).
  - CAMPUS bounds and center constants from `site.ts`.
  - All **23** `TRE-*` trees from `trees.ts` — 11 verified, 6 pending,
    4 incident, 2 unverified.

### Map surface (`map_screen.dart` rewrite)

- `flutter_map` + `latlong2` real map with `CameraFit.bounds` over the UEP
  Catarman campus bounds.
- OSM street tiles by default; Esri World Imagery satellite toggle in the
  header (layer label swaps `Streets` ↔ `Satellite`).
- Soft zone halo rectangles mirroring the admin `framingBounds` padding.
- Pin markers for all 23 trees at their real coordinates (existing
  `TreeMarker`/`PinTailPainter` look preserved, plus a selected-ring state).
- GPS position dot at the campus center and a recenter control.
- Zoom filter panel:
  - Zone pills (`All zones`, `Zone I/II/III`) with live tree counts.
  - Status tiles (`All statuses`, Verified/Pending/Incident/Unverified) with
    live counts; active filter badge on the toggle button.
- Bottom-sheet details card with species, zone, planter, planted date,
  coordinates, status, `Start Verification` (opens the scanner) and
  `Report incident` (opens `IncidentReportScreen`, now wired).
- Compact custom attribution chips (`© OpenStreetMap` / `© Esri`).

### Cleanup

- Added `INTERNET` permission to `android/app/src/main/AndroidManifest.xml`.
- Deleted `painters/field_map_painter.dart`, `widgets/map/map_label.dart`,
  `widgets/map/map_legend.dart`, and the now-unused `shared/legend.dart`.
- Replaced leftover `T-*` codes in `sync_dashboard_screen.dart` mocks and the
  manual-entry hint with admin `TRE-*` tags.
- Added `flutter_map ^8.3.2` and `latlong2 ^0.10.1` dependencies.

### Global network monitoring (`connectivity_plus`)

- Added `connectivity_plus ^7.3.1` and the `ACCESS_NETWORK_STATE` Android
  permission; the map tile pipeline now has an app-level online/offline story
  instead of failing silently.
- New `lib/core/connectivity/` layer (no feature dependencies):
  - `connection_status.dart` — `enum ConnectionStatus { online, offline }`,
    re-exported through `sync_state.dart` for the sync dashboard.
  - `connectivity_controller.dart` — a single app-lifetime `ValueNotifier`
    owning the only `connectivity_plus` subscription. Seeds itself via
    `checkConnectivity()`, debounces stream flips (600 ms) so Wi-Fi/mobile
    handoffs cannot flicker the UI, and `initialize()` is idempotent. With no
    platform channel (widget tests) it silently keeps the seeded status.
  - `app_connectivity_scope.dart` — `InheritedNotifier` exposing
    `AppConnectivityScope.statusOf(context)` so only the widgets that read the
    status rebuild on a flips.
  - `connectivity_banner_host.dart` — global notice host wired through
    `MaterialApp.builder` above the Navigator:
    - Startup offline → non-dismissable-by-background "No internet
      connection" dialog (waits for `endOfFrame` so the Navigator exists).
    - online → offline while running → error snack bar.
    - offline → online → "Internet Connected" snack bar.
- `main.dart` refactor: `EcoTraceApp` is now a `StatefulWidget` owning (or
  receiving, for tests) the controller plus `navigatorKey`/
  `scaffoldMessengerKey`; its `MaterialApp.builder` wraps `AppConnectivityScope`
  → `ConnectivityBannerHost` → child.
- `MapHeader` gained `isOnline` and renders a lime/error dot + `Online`/
  `Offline` label; `MapScreen` reads status via `AppConnectivityScope`.
- Debugging note: `connectivity_plus`'s `MethodChannelConnectivity` calls the
  method **`check`** (not `checkConnectivity`), and its change stream lives on a
  separate `connectivity_status` event channel. `setMockMethodCallHandler` in
  Flutter 3.47+ auto-wraps the handler's return value in a success envelope, so
  mocks return the plain `['wifi']`/`['none']` list.

### Performance: isolated, memoized map canvas

- New `lib/features/home/presentation/widgets/map/map_canvas.dart` — tiles, zone
  halos and markers extracted to their own widget tree.
  - `_MapCanvasState` memoizes the built `FlutterMap` subtree and rebuilds it
    only from `didUpdateWidget` when an input actually changes (satellite,
    zone/status filter, selected tree, callbacks). Opening the filter panel,
    tapping the header or animating the details sheet no longer recreates the
    ~23-marker `MarkerLayer`.
  - `MapScreen` binds stable callback singletons once (`late final` fields) so
    the canvas can detect no-change; map taps and filter toggles that don't
    alter state are no-ops instead of full-chrome rebuilds.
- Camera roam guard: `CameraConstraint.containCenter` over campus bounds padded
  by ~2 campus-widths with `tileBounds` set to the same area.
  - Panning can no longer drift into empty open map and *cannot* fetch tiles
    outside the campus zone (zero wasted tile traffic at the fringes).
  - `containCenter` (not `contain`) keeps zoom-out unrestricted — no
    stuck-zoom at the campus edge — and never returns null, so the
    recenter button's `move(center, 16)` stays legal everywhere.
  - `initialCenter`/`initialZoom` pinned on-campus so flutter_map's
    constraint pre-flight assert passes before the `CameraFit.bounds` runs.
- Tile pipeline:
  - One long-lived `NetworkTileProvider` shared by every `TileLayer` rebuild
    (single `RetryClient`/connection pool instead of one per build).
  - `BuiltInMapCachingProvider` with `overrideFreshAge: 7 days` — the ~90
    campus tiles stay fresh from disk for a week instead of re-validating
    OSM/Esri on every visit.
  - `TileDisplay.fadeIn(80ms)` keeps the pop-in snappy; `keepBuffer`/`panBuffer`
    left at flutter_map defaults (2/1).
- Raster-layer caches: `RepaintBoundary` around each tree marker and around
  `FlutterMap` and the details sheet, so pans and sheet slides reuse cached
  paintings instead of re-drawing shadows + labels every frame.
- Details sheet slide shortened 350ms → 250ms.

## Tests

- Navigation test now asserts on the real map (header layer label + a real
  marker code) instead of the old grid label.
- New map regression test:
  - filter panel opens with zone/status controls,
  - status filter keeps verified trees only,
  - zone filter keeps Zone II trees only,
  - tree details bottom sheet opens for a marker,
  - `Report incident` navigates to the linked incident report.
- Manual-verification draft test updated to the `TRE-0892` tag.
- Tests deliberately avoid `pumpAndSettle` near tile loading and assert on
  marker codes/filter chips, not map tiles.
- New connectivity harness (`_connectivityHarness` in `widget_test.dart`)
  reproduces the real `EcoTraceApp.builder` wiring with an injectable
  controller; a channel mock stubs the connectivity platform.
- New connectivity tests:
  - Offline at launch → "No internet connection" dialog appears above the
    shell and dismisses via `OK`.
  - Connectivity transitions → map header flips `Online` ↔ `Offline` and the
    snack bars raise/lower on offline→online and online→offline.

## Validation

```powershell
flutter pub get     # OK
flutter analyze     # No issues found
flutter test        # 11/11 passed
flutter build apk --debug  # app-debug.apk built
```

## Current State

The Map tab is now a real, zoomable, filterable campus map backed by the same
tree inventory as the admin portal. Tile loading requires network access
(`INTERNET` permission added), and the app now tracks connectivity globally:
it seeds the status at startup, shows a blocking offline dialog when launched
without a connection, raises/lowers "connected"/"offline" snack bars on
transitions, and the map header reflects the live status. Trees, zones, and
statuses remain locally seeded from the admin portal dataset; there is still no
backend synchronization, GPS locking, or live status updates.

## Next Review Gate

Confirm the interactive map + connectivity behavior on a device (tile loading
over the network, satellite toggle, filter counts, bottom-sheet actions,
airplane-mode transition dialogs/snack bars) before moving to backend-connected
verification and synchronization flows.