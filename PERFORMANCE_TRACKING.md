# EcoTrace — Performance Fix Tracker

Living record of the performance work. Every code change is logged here so we
always know **what is being changed and what is not**. Gates = `flutter analyze`
clean + `flutter test` green (+ DevTools frame timings once hardware is present).

Legend: ⏳ pending · 🔧 applied (code changed) · ✅ verified (gates green) · 🚫 not doing / resolved-elsewhere

## Status

| ID | Finding | Location | Fix | Status |
|----|---------|----------|-----|--------|
| P0-1 | 24σ `BackdropFilter` re-rasterizes on every keystroke/focus/toggle/keyboard frame | `staff_auth_screen.dart` | Removed `RepaintBoundary`/`ClipRRect`/`BackdropFilter` + `import 'dart:ui'`; card keeps its translucent fill, radius, border, shadow | ✅ verified |
| P0-2 | 200 ms keyboard glide `AnimatedPadding` animated the blur | `staff_auth_screen.dart` | Keep the animation — blur removal makes it cheap | 🚫 resolved-by-P0-1 |
| P1-1 | Eager `IndexedStack` mounts the live `FlutterMap` (tiles + 23 markers) offstage on every tab | `app_shell.dart` | `_LazyTab` gates the map slot on `active` and caches the subtree after first visit | ✅ verified |
| P1-2 | 4 MB `ecotrace_icon.png` decode on splash | `splash_screen.dart` | `cacheWidth/Height: 320` | ✅ verified |
| P1-3 | 4 MB icon decode on auth badge | `staff_auth_screen.dart` | decode at 2× badge size | ✅ verified |
| P2-1 | 166 AA circles painted at native res (first-frame backdrop) | `staff_auth_screen.dart` `_CanopyPainter` | seeded counts 44→28, 16→10, 84→54, 22→14 (92 AA circles overall) | ✅ verified |
| P2-2 | Login/sign-up toggle rebuilds the entire form | `staff_auth_screen.dart` | Sign-up-only fields extracted to `_signUpPreUsernameFields()` / `_signUpConfirmFields()`; parent swaps single nodes | ✅ verified |
| P3-1 | Redundant outer `RepaintBoundary` per marker | `map_canvas.dart` | removed outer boundary (marker self-boundaries remain) | ✅ verified |
| P3-2 | Per-`_visibleEvents` search-string recompute on every filter pass | `events_screen.dart` | `static final _searchText` map precomputed at class load | ✅ verified |
| P3-3 | Fresh `ThemeData` allocated per getter access | `app_theme.dart` | `static final light = _buildLight()` singleton | ✅ verified |
| P3-4 | 96 KB tracked dead `.backup` | `app_shell.dart.backup` | `git rm`'d | ✅ verified |
| P3-5 | 914 KB icon + 19.3 MB APK, no ABI splits | assets / `build.gradle.kts` | recompress icon (`pngquant`) + ABI splits | 🚫 deferred |

## Implementation notes (learnings this session)

- **`IndexedStack` is eager in this Flutter version.** A probe test proved all four
  tab children (incl. `MapScreen`) are inflated at `AppShell` startup and kept
  offstage. Lazy-through-`IndexedStack` therefore needs an explicit `active` gate:
  `_LazyTab` builds `MapScreen` only while the Map tab is on screen, then returns
  the cached instance forever (state survives tab switches). Verified by probe:
  `MapScreen` mounted **0** at startup → **1** after first Map tap → still **1**
  (offstage) after switching to Alerts.
- **A first `_LazyTab` draft was wrong** (`_built` bool returning `SizedBox.shrink`
  after the first build) — it tore down the map element on the tab-switch rebuild
  and broke 5 widget tests. The `_cached ??=` form fixes it; all 11 tests pass.
- P2-2: the pre-username (names + staff-type) and post-password (confirm) blocks
  are separated by the shared username/password fields, so they became two
  methods rather than one. Behavior (controllers, validators, autofocus,
  `ValueListenableBuilder` sources) is unchanged — the diff is pure extraction.
- P0-1 also made `ImageFilter` unused, so `import 'dart:ui';` had to go too.

## Deliberately not changing

- Map `didUpdateWidget` memoization, roam bounds + tile cache, per-marker
  `RepaintBoundary`, fade-only route transitions, connectivity debounce — keep as-is.
- P0-2 keyboard glide keeps its 200 ms animation; only the blur (the expensive
  part of each animated frame) is gone.
- P3-5 size work deferred until runtime perf is measured on device.
- Pre-existing uncommitted work in `main.dart` / `connectivity_banner_host.dart`
  (offline startup-dialog removal) and `test/widget_test.dart` — untouched.
- Signs/sizes of the backdrop circle layers are unchanged (only counts, P2-1);
  the canopy pattern stays visually dense.

## Verification log

| Run | Result |
|-----|--------|
| Baseline (before audit) | `flutter analyze` clean; `flutter test` 11/11 |
| After P0-1, P2-1, P2-2 (auth) | `flutter analyze` clean; 5 map-tab tests failing (pre-`_LazyTab` v2) |
| After P1-1 `_LazyTab` v2 (active-gated) | `flutter analyze` clean; `flutter test` 11/11 |
| Probe (laziness proof) | startup `MapScreen` mounted=0; after Map tap mounted=1 onstage=1; after leaving, still mounted (state kept) |
| After P3-2…P3-4 | `flutter analyze` clean; `flutter test` 11/11 |
| Phase 5 — device frame timings | **blocked — no hardware available**; run `flutter run --profile` + DevTools timeline (typing / mode toggle / tab switch / map pan) before→after once a device is attached |