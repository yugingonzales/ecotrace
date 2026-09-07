# EcoTrace Phase 2 Progress: Frontend Shell

## Completed

- Added `lib/features/home/presentation/app_shell.dart`.
- Added a shared mobile bottom navigation matching the web reference.
- Added Events screen with dark-green activity header, calendar ribbon, activity cards, location details, attendee avatars, and confirmation controls.
- Added Map screen with reference-style grid map, tree status markers, GPS marker, legend, selected-tree details, and verification action.
- Added Scanner screen with QR/NFC viewfinder treatment, GPS status, and manual tree verification fallback sheet.
- Added Alerts screen with filter pills, selected/urgent/info statuses, and alert cards.
- Added Profile screen with monitoring staff identity, account details, sync status, and sign-out action.
- Added Incident Report screen linked to the selected tree code.
- Added Sync Dashboard screen with pending/synced feedback states and audit history.
- Connected valid local authentication submission to the frontend shell.
- Added a widget test covering Events -> Map -> Alerts navigation.
- Added responsive phone-viewport coverage for the shell, scanner entry, and sync dashboard entry.
- Added local interaction feedback for alert filters/details, map verification, and sync refresh.
- Fixed narrow-phone overflow in event, profile, sync, and audit-history layouts.
- Added typed domain boundaries for `TreeRecord`, `IncidentReport`, and `SyncSummary`.
- Optimized navigation density for compact Android widths.
- Added scale-down protection for the auth brand lockup.
- Added 320x568 and 360x780 responsive regression coverage and fixed narrow-screen overflows.
- Made the Events tab functional with local schedule data, date selection, search, joined-only filtering, event details, participation confirmation, and empty results state.
- Added interaction regression coverage for event details, participation, search, and date switching.
- Expanded manual verification into a validated offline draft form with tree tag, DBH, crown dimension, plant status, measurement source, and notes.
- Added validation coverage for required and positive measurement fields plus successful draft confirmation.
- Enlarged and elevated the center tree-verification action so it visibly floats above the bottom navigation, with a compact-width variant.
- Redesigned the Map surface with layered terrain, water, access roads, survey parcels, vegetation zones, labels, compass/scale context, and pin-shaped tree markers.

## Current State

This is a frontend preview using local mock data. The scanner does not access the camera or NFC hardware yet. Map markers, events, alerts, profile values, incident reports, verification feedback, and synchronization status are placeholders until the backend and device capability contracts are confirmed.

## Review Steps

1. Run `flutter run` on an Android emulator or connected device.
2. Enter any non-empty staff number and a password of at least 8 characters on Login.
3. Review Events, Map, Alerts, Profile, and the center scanner action.
4. Open manual tree verification from the scanner and check DBH/crown dimension field wording and units.
5. Compare spacing, colors, card radius, bottom navigation, and map treatment with the reference files.
6. Open the selected tree incident report from Map.
7. Open the synchronization dashboard from Profile > Sync status.
8. Record any visual changes before connecting real data.

The automated frontend checks currently cover authentication rendering, primary tab navigation, scanner entry, sync dashboard entry, and a 360x780 phone viewport.

## Next Review Gate

Confirm the frontend information hierarchy and the authoritative API contracts before implementing network authentication, camera/NFC scanning, GPS capture, local drafts, or synchronization behavior.