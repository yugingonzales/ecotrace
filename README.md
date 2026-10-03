# EcoTrace

Flutter **Android-only** app for environmental tree monitoring, third-party
auditing, field verification, incident reporting, and synchronization of audit
feedback.

> ### 📖 Documentation lives in [`DOCUMENTATION.md`](DOCUMENTATION.md)
>
> That file is the single source of truth: product goals, design tokens,
> architecture, a feature-by-feature reference, domain contracts, performance
> history, the open work queue, settled decisions, and the full progress log.
>
> This README is intentionally short so the two cannot drift.

## Quick facts

| | |
|---|---|
| Platform | Android only |
| Stack | Flutter · Material 3 · `flutter_map` · `geolocator` · `http` · `image_picker` |
| Source | 69 Dart files in `lib/` |
| Tests | 71, all passing |
| State | High-fidelity frontend. **No backend, no persistence.** |

## Current gates

```powershell
cd C:\flutter_workspace\ecotrace
flutter pub get
flutter analyze      # clean
flutter test         # 71/71
```

## What works today

Events with a date-aware calendar and participation receipts · a real campus map
with 23 admin-sourced trees, filters and OSRM routing · on-site tree verification
(analysis mode → proximity gate → 4-step wizard with camera evidence) · incident
reporting · alerts · profile · a three-state connectivity model that
distinguishes "radio on" from "internet actually works" · a field-progress
dashboard.

## What does not

Authentication is not connected to a backend. Nothing is persisted — a
verification or an event join is lost on app restart. Tree data is a local
transcription of the admin portal. The tree-scanning and NFC/QR paths are mock
only. See §7 and §8 of `DOCUMENTATION.md` for the full queue and limitations.

> ⚠️ **The proximity gate is currently disabled**
> (`VerificationProximity.enforcementEnabled == false`) so the verification UI can
> be tested without a GPS fix. Restore it before recording real field data — see
> §4.4.

## Working on this repo

[`ai_instructions.md`](ai_instructions.md) is **binding**: scan context first,
plan before acting, document every change, clean up temporary files, and never
run `git commit` / `git push`.

## Reference material

| Source | Path |
|---|---|
| Original web design | `C:/Users/USER/Desktop/adi/New folder` |
| Admin portal (authoritative tree inventory) | `C:/laragon/www/ecotrace_admin` |