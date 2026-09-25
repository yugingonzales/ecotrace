# EcoTrace — Performance Optimization Report

**Scope:** Runtime lag / jank audit of the Flutter app in `C:\flutter_workspace\ecotrace\`.
**Method:** Static code audit of every `lib/` file (49 files), `pubspec.yaml`, Android
manifest / Gradle config, assets, and git history. Baseline validated with
`flutter analyze` (clean) and `flutter test` (11/11 passing). No device
available in this environment, so timings below are **expectations from the
code paths**, not measured frame times — verify on hardware with DevTools
(see "How to measure" at the end).

## 1. Headline findings (priority order)

| Pri | Location | Issue | Cost when triggered |
|-----|----------|-------|---------------------|
| **P0** | `staff_auth_screen.dart:210` | 24σ `BackdropFilter` over the entire auth form | Re-blurs the full card every keystroke, focus change, login/sign-up toggle and keyboard frame — the single most likely cause of the auth screen lag |
| **P1** | `app_shell.dart:32` | `IndexedStack` builds and keeps a live `FlutterMap` on every tab | Full map subtree (tile pipeline, decoded tiles, 23 marker layers) alive from login even if the user never opens the Map tab; startup hitch + RAM |
| **P1** | `splash_screen.dart:138`, `staff_auth_screen.dart:846` | Assets decoded at full source resolution | `ecotrace_icon.png` is 1024×1024 (~4 MB RGBA) but drawn at 52–160 px — decode spike + retained memory + GPU downscale every frame |
| **P2** | `staff_auth_screen.dart:712` | Auth backdrop paints 166 antialiased circles at full native resolution | One-shot but heavy first paint right at the splash→auth transition |
| **P2** | `staff_auth_screen.dart:618` | Login/sign-up toggle rebuilds the entire ~500-line form *through the blur* | Mode switch jank (compounds P0) |
| **P3** | `map_canvas.dart:214` (fixed), `events_screen.dart:79`, `app_theme.dart:20` | Redundant `RepaintBoundary` (fixed), per-build recompute, theme re-allocation | Minor; first two mitigated below |
| **P3** | Repository / APK hygiene | 96 KB tracked `.backup`, 914 KB icon, no ABI splits | Build/repo bloat, not runtime jank |

**Already done well (credits):** map canvas memoization (`didUpdateWidget` guard),
camera roam bounds that block out-of-campus tile traffic, shared 7-day
`BuiltInMapCachingProvider`, per-marker raster cache, fade-only route
transitions (no scaling of the glass blur), debounced connectivity, hoisted
validators/border instances, lazy calendar strip. These are the right patterns
and should be preserved.

---

## 2. P0 — 24σ `BackdropFilter` on the auth form

**Evidence:** `staff_auth_screen.dart:205-215`

```dart
RepaintBoundary(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(_glassRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),   // ← heavy
      child: Container(/* the whole login/sign-up card */),
```

**Why it hurts.** A `BackdropFilter` makes the compositor save the entire backdrop
behind the widget into an offscreen texture and run a Gaussian blur over it
*every time its subtree repaints*. At σ=24 (very high) the fill-rate cost scales
with the card area (~300–400 × 700+ logical px) and is especially punishing on
mid/low Android GPUs. In this screen the blur re-runs whenever any of these
happen — each one while driving an animation:

- **Text input** — every keystroke repaints the fields inside the blur region.
- **Focus changes** — bordered field repaint.
- **Login ↔ Sign-up toggle** — full `setState()` of the form (line 620).
- **Keyboard open/close** — `AnimatedPadding` (line 179) slides the card for
  200 ms, re-blurring every frame of the slide.

**Recommended fix (design-preserving, big win):** drop the blur to a mild frost
and keep the existing translucent fill — the glass look is mostly carried by
`Colors.white.withValues(alpha: .10)` anyway:

```dart
BackdropFilter(
  // σ=24 was re-rasterizing the whole card on every interaction.
  // 8σ keeps a visible frost at a small fraction of the fill-rate cost.
  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
  child: Container(...)
```

**Alternative (zero-blur, maximally cheap):** remove `BackdropFilter`/`ClipRRect`
entirely and rely on the card's translucent fill:

```dart
child: Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(_glassRadius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
  ),
  // ...existing form column...
)
```

**Complementary keyboard fix:** the moving blur during keyboard animation is the
worst offender, and it exists only because the scroll view re-instates the
`windowSoftInputMode="adjustResize"` inset. Replace the animated inset padding
with a non-animated one (or set `resizeToAvoidBottomInset: true` on the
`Scaffold` and delete the padding dance):

```dart
// Before (animates 200ms → 12 re-blurred frames):
// child: AnimatedPadding(
//   duration: const Duration(milliseconds: 200),
//   padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
//   child: ...
// )
// After:
padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
```
---

## 3. P1 — The map is alive on every tab (`IndexedStack`)

**Evidence:** `app_shell.dart:22-40`

```dart
const pages = <Widget>[
  EventsScreen(),
  MapScreen(),        // ← built on login, kept alive forever
  SizedBox.shrink(),
  AlertsScreen(),
  ProfileScreen(),
];
body: IndexedStack(index: _index, children: pages),
```

`IndexedStack` builds and lays out **all five children** at startup and never
disposes them. `MapScreen` → `MapCanvas.initState()` therefore runs at login:
`FlutterMap` construction, the initial `CameraFit.bounds` fit, the tile
pipeline warm-up, and `NetworkTileProvider` setup — plus decoded tile textures
and the 23 marker layers stay resident for the whole session. This work competes
with the splash→auth→shell transition, and every tab pays map memory even when
the user stays on Events.

**Fix — lazy-build the map tab on first visit (instant tab switching is kept,
map startup cost moves to the first "Map" tap):**

```dart
class _LazyTab extends StatefulWidget {
  const _LazyTab(this.builder);
  final WidgetBuilder builder;
  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> {
  bool _visited = false;
  @override
  Widget build(BuildContext context) {
    if (!_visited) {
      _visited = true;             // build once on first show, then hold it
      return widget.builder(context);
    }
    return const SizedBox.shrink(); // placeholder until first visit
  }
}

// in _AppShellState.build:
final pages = <Widget>[
  const EventsScreen(),
  _LazyTab((context) => const MapScreen()),
  const SizedBox.shrink(),
  const AlertsScreen(),
  const ProfileScreen(),
];
```

> `IndexedStack` is what preserves per-tab state across switches; the one-time
> construction keeps that behavior while deferring the heavy map subtree.

## 4. P1 — Full-resolution asset decodes (image memory + decode spikes)

**Evidence:**

- `ecotrace_icon.png` is **1024×1024 — 914 KB** on disk ≈ **4 MB decoded RGBA**.
- `splash_screen.dart:138` draws it at **160×160**; `staff_auth_screen.dart:846`
  (`_LogoBadge`) draws it at **52 / 64 px**.

Without `cacheWidth`/`cacheHeight`, `Image.asset` decodes the *source*
resolution and the GPU downscales at paint time: a ~4 MB buffer is retained per
unique size and the full-res decode hits the splash's first frame and again
on the auth screen.

**Fix — decode at ≈2× the display size (already applied in this audit):**

```dart
// splash_screen.dart
Image.asset(
  'lib/assets/icons/ecotrace_icon.png',
  width: 160,
  height: 160,
  cacheWidth: 320,           // 2× displayed size: sharp up to 2x DPR
  cacheHeight: 320,
  filterQuality: FilterQuality.medium,
),
```

```dart
// staff_auth_screen.dart — _LogoBadge.build
Image.asset(
  assetPath,
  width: size,
  height: size,
  fit: BoxFit.cover,
  cacheWidth: (size * 2).round(),
  cacheHeight: (size * 2).round(),
),
```

This cuts retained image memory for the icon from ~4 MB to ~400 KB and removes
the full-res decode on the splash's first frame.
## 5. P2 — Auth backdrop first paint

**Evidence:** `staff_auth_screen.dart:712-756` — `_CanopyPainter.paint()` draws
44 + 16 + 84 + 22 = **166 antialiased `drawCircle`s** (radii up to ~152 px) at
**full native resolution** (e.g. 1080×2400 @ 2.75 DPR ≈ 2970×6600 px canvas).

`shouldRepaint => false` means it paints once and caches — but that *once* is
the auth screen's first frame, right at the splash→auth fade. On low-end
devices a ~3000×6600 canvas of 166 AA circles can blow the frame budget.

**Mitigation (visual-equivalent):** reduce the stroke count while keeping the
density gradient the eye perceives (the glints are what read as foliage):

```dart
// _CanopyPainter.paint — reduce per-loop counts:
const moundCount = 28;   // was 44
const paleCount   = 10;  // was 16
const glintCount  = 54;  // was 84
const dotCount    = 14;  // was 22
```

If the designer allows it, a flat gradient (drop the painter entirely) is the
zero-cost option — the canopy glow is already produced by the two `RadialGradient`
`DecoratedBox`es above the painter.

## 6. P2 — Login/sign-up toggle rebuilds the whole form through the blur

**Evidence:** `staff_auth_screen.dart:618-623`

```dart
_AuthModeLink(
  loginMode: _loginMode,
  onTap: () => setState(() => _loginMode = !_loginMode),
),
```

One `setState` rebuilds the entire ~500-line form *and* re-runs the blur (P0).
`ValueListenableBuilder`s already localize password/staff-type updates; the
mode toggle should follow the same pattern.

**Fix — extract the two mode-specific field blocks into small widgets:**

```dart
// Parent keeps `_loginMode`; the tree only swaps these two children:
_loginMode
    ? const _LoginModeOnlyFields(/* username, password, submit, hint, link */)
    : const _SignUpSuffixFields(/* personal + staff fields */)
```

A mode switch then repaints only the swapped region — the header, password
field, submit button and the blurred backdrop region stay untouched.

## 7. P3 — Minor wins

1. **Redundant `RepaintBoundary` per marker** — `map_canvas.dart:214` wrapped
   `TreeMarker` in a second `RepaintBoundary` while `tree_marker.dart:24` already
   wraps itself. **Fixed:** outer boundary removed; each marker keeps its own
   cached raster layer during pans.
2. **`events_screen.dart:79-88`** — `_visibleEvents` rebuilds lowercased search
   strings for every event on every build. Trivial at 4 events; precompute a
   searchable string per event once in a `Map<LocalEvent, String>` if the
   dataset grows.
3. **`app_theme.dart:20`** — `static ThemeData get light` allocates a fresh
   `ThemeData` per access. `MaterialApp` reads it once, but hoisting to
   `static final ThemeData light = ...` makes the cost explicit.
4. **Repository hygiene** — `lib/features/home/presentation/app_shell.dart.backup`
   (96 KB, tracked) is dead code from a pre-refactor; delete it.
   `lib/assets/icons/ecotrace.png` (1 MB) is not in `pubspec.yaml` (not bundled);
   it is only a source for `tools/regenerate_icons.py`.
5. **App size (not frame time)** — the 914 KB `ecotrace_icon.png` (recompress
   with `pngquant --strip` ≈ 60–80% smaller) and the 19.3 MB release APK with no
   ABI splits. Adding `splits { abi { enable true universalApk false } }` to
   `android/app/build.gradle.kts` shrinks install size significantly.

## 8. Already optimized (keep as-is)

- **Map rebuild guards** — `MapCanvas.didUpdateWidget` compares primitives and
  `identical()` callbacks; chrome `setState`s (filters, header, sheet slide)
  never recreate the `FlutterMap`/`MarkerLayer` subtrees.
- **Tile traffic** — `CameraConstraint.containCenter` + `tileBounds` over the
  padded campus box mean zero tile fetches outside the site; the 7-day fresh
  cache serves revisits from disk; one shared `NetworkTileProvider` keeps a
  single connection pool.
- **Raster caching** — per-marker `RepaintBoundary`, plus boundaries around
  `FlutterMap` and the details sheet make camera pans composites of cached
  layers.
- **Transitions** — splash & auth routes are pure opacity fades; the code
  comments document that scale/slide used to re-rasterize the blur.
- **Connectivity** — 600 ms debounce, single app-lifetime subscription,
  `InheritedNotifier` scoping so flips touch only the map header.

## 9. How to verify on hardware (before/after each fix)

```powershell
flutter run --profile   # never use --profile timings from a debug build
```

In DevTools → **Performance**, record a timeline while:

1. opening the keyboard on the auth screen and typing,
2. toggling Login ↔ Sign-up,
3. switching tabs Events ↔ Map and panning/zooming the map,
4. opening the tree details sheet.

Watch the Frame Chart (red = frames over the 16 ms budget) and the raster
("P") rows; enable **Repaint Boundaries** to see which layers re-rasterize.

Expected deltas:

| Interaction | Before | After (snippets applied) |
|-------------|--------|--------------------------|
| Auth keyboard open + typing | dropped frames (blur re-raster) | steady 60/90 fps |
| Login ↔ Sign-up toggle | visible hitch | instant |
| Splash → auth transition | possible first-frame drop (backdrop paint) | smooth fade |
| Login → shell | startup hitch (map build) | no map work until first Map tap |
| Map pan (post-cache) | already smooth | unchanged (memory drops) |

## 10. Changes applied in this audit

1. `lib/features/splash/presentation/splash_screen.dart` — splash icon now
   decoded at 320×320 via `cacheWidth/cacheHeight` (visual-neutral).
2. `lib/features/auth/presentation/staff_auth_screen.dart` — `_LogoBadge`
   images decoded at 2× badge size (visual-neutral).
3. `lib/features/home/presentation/widgets/map/map_canvas.dart` — removed the
   redundant outer `RepaintBoundary` around each `TreeMarker` (visual-neutral).

Revalidated after the edits: `flutter analyze` clean and `flutter test`
11/11 passing.

The P0 blur reduction (Section 2), P1 lazy map tab (Section 3), and P2
backdrop / form-split changes (Sections 5–6) are **not yet applied** because
they alter the visual design or the tab-switching cost model. They are
drop-in from the snippets above once you confirm the direction.