# EcoTrace Flutter Android

EcoTrace is a Flutter Android mobile application for environmental tree monitoring, third-party auditing, field verification, incident reporting, and synchronization of audit feedback.

This README is the implementation handoff document. A future developer or AI model should read it before changing the project. Continue from the current phase instead of recreating the application from scratch.

## Product Goal

Convert the existing EcoTrace web design into a native Android workflow for monitoring personnel.

The application must support:

1. Secure authentication for the `MONITORING_STAFF` entity.
2. Field verification of tree records using camera-assisted measurement or manual fallback.
3. Incident reports for damaged or missing trees.
4. A synchronization dashboard showing feedback, status, and audit history.

The app is strictly Flutter Android. Do not add iOS, web, desktop, or platform-specific product flows unless explicitly requested.

## Reference Design

The original web project is located at:

`C:/Users/USER/Desktop/adi/New folder`

Important reference files:

- `login.html`: authentication layout and labels.
- `css/login.css`: Phase 1 colors, spacing, borders, and component styling.
- `index.html` and `css/add.css`: scanner and field collection visual direction.
- `alerts.html`, `events.html`, and `map.html`: future dashboard, incident, and map concepts.

The admin portal that owns the authoritative tree inventory and map geometry is at:

- `C:/laragon/www/ecotrace_admin` — `src/lib/trees.ts` (tree inventory + statuses) and `src/lib/site.ts` (UEP Catarman zones, campus bounds, mapping helpers). The Flutter map transcribes this data into `lib/features/home/presentation/models/campus_data.dart`.

The current native theme is based on these web tokens:

| Token | Value | Usage |
| --- | --- | --- |
| Forest | `#0D382C` | Primary buttons, active tabs, main brand surface |
| Deep forest | `#0B1F17` | App background and header contrast |
| Dark forest | `#0A2A20` | Header gradient/source color |
| Lemon | `#FFD600` | Logo, scan actions, emphasis |
| Canvas | `#F4F7F5` | Form and page background |
| Field | `#FFFFFF` | Text inputs and clean content surfaces |
| Border | `#E1E8E3` | Input borders and separators |
| Muted | `#6B8277` | Helper text and secondary labels |
| Soft text | `#8EB3A0` | Dark header supporting text |
| Error | `#C74545` | Validation and destructive status |

Preserve the existing visual language: compact mobile screens, rounded controls, strong dark-green contrast, lemon action accents, and readable form spacing.

## Current Status: Phase 2 Shell + Phase 3 Real Map Port

The current implementation contains:

- Flutter Android project scaffold generated in this repository.
- App entry point in `lib/main.dart`.
- Shared design tokens and Material 3 theme in `lib/core/theme/app_theme.dart`.
- `StaffType` and `MonitoringStaff` domain model in `lib/features/auth/domain/monitoring_staff.dart`.
- Native authentication screen in `lib/features/auth/presentation/staff_auth_screen.dart`.
- Login and staff sign-up modes.
- Staff ID, staff number, staff type, password, and confirmation fields.
- Local required-field and password-length validation.
- Password visibility toggle.
- Review-only SnackBar feedback after valid submission.
- Smoke test in `test/widget_test.dart`.
- Phase notes in `PHASE_1_PROGRESS.md`.
- Reference-matched frontend shell in `lib/features/home/presentation/app_shell.dart`.
- Incident report and synchronization dashboard frontend previews.
- Local interaction feedback and narrow-phone responsive coverage.
- Typed domain contracts for tree records, incidents, and synchronization state.
- Responsive layout tuning for compact Android screens, including adaptive navigation and auth branding.
- Functional offline Events tab with local schedule actions and search/filter behavior.
- Functional offline manual tree-verification draft form aligned with `TREE_RECORD` fields.
- Enlarged floating tree-verification action with responsive compact-phone sizing.
- Realistic offline field-map presentation with terrain, roads, parcels, water, and pin markers.
- Phase 2 frontend notes in `PHASE_2_PROGRESS.md`.
- Real interactive campus map in the Map tab using `flutter_map` + `latlong2` (OSM street tiles by default).
- Esri World Imagery satellite layer toggle in the map header.
- All 23 georeferenced admin `TRE-*` trees (real lat/lng) with admin zone/status vocabulary and marker colors.
- Zone chips and status filter panel with live inventory counts.
- Bottom-sheet tree details: species, zone, planter, planted date, coordinates, status, `Start Verification` (opens the scanner) and `Report incident` (opens the linked incident form).
- Replaced the synthetic CustomPaint grid (deleted `field_map_painter.dart` and `map_label.dart`); left-over `T-*` mock tags updated to admin `TRE-*` tags.
- `INTERNET` permission added to the Android manifest for map tile downloads.
- Phase 3 notes in `PHASE_3_PROGRESS.md`.

### Intentional Preview Limitations

Authentication is not connected to a backend yet. A valid local form submission only opens the frontend preview. No password is hashed, persisted, transmitted, or compared. No access token, refresh token, session, or route guard exists yet. The scanner, events, alerts, profile, and sync state currently use local mock data. The Map tab now renders real OSM/satellite tiles and the admin portal's tree inventory (seeded locally), but tree statuses and records are not yet fetched from or pushed to a backend.

The API contract, password hashing responsibility, staff ID format, and authorization rules must be confirmed before implementing production authentication.

## Architecture Direction

Use feature-first organization with clear presentation, domain, data, and shared-core boundaries:

```text
lib/
  main.dart
  core/
    theme/
    routing/
    errors/
    network/
    storage/
    widgets/
  features/
    auth/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        screens/
        widgets/
        state/
    field_verification/
      data/
      domain/
      presentation/
    incidents/
      data/
      domain/
      presentation/
    synchronization/
      data/
      domain/
      presentation/
```

Keep widgets focused on rendering and user interaction. Put validation and business rules in domain/use-case code once the features become connected to data. Keep HTTP, local storage, camera, OpenCV, and synchronization details out of presentation widgets.

## Planned State Management

Choose one predictable state-management approach before Phase 2 and use it consistently. A lightweight notifier-based approach is acceptable for the first connected slices; Riverpod or Bloc are also acceptable if the dependency and conventions are introduced deliberately.

Required state boundaries:

- `AuthState`: signed out, submitting, authenticated, failure.
- `FieldVerificationState`: draft, capturing, manual entry, submitting, submitted, failed.
- `IncidentState`: draft, submitting, submitted, failed.
- `SyncState`: online, offline, syncing, synced, conflict, failed.

Avoid global mutable state and do not place API calls directly in screen widgets.

## Domain Contracts

### `MONITORING_STAFF`

The initial schema is:

```text
staff_id       : unique identifier
staff_number   : login/business identifier
password_hash  : server-side password hash; never store plaintext
staff_type     : intern | paid volunteer | staff
```

Recommended future fields, pending backend confirmation:

```text
display_name
email
phone_number
active
created_at
updated_at
last_login_at
```

The client should receive an authenticated session/token response, not the password hash.

### `TREE_RECORD`

The field verification flow must mirror the backend tree record attributes. At minimum, plan for:

```text
tree_id
tree_code or tag
species
latitude
longitude
dbh
crown_dimension
plant_status
verification_status
verified_by_staff_id
verified_at
photo_evidence
notes
```

The exact field names, units, enum values, required fields, and server ownership must be confirmed from the backend schema before finalizing models. DBH and crown dimension must display units explicitly.

### Incident Report

An incident should be linked to both the affected tree and the monitoring personnel:

```text
incident_id
tree_id
reported_by_staff_id
incident_type: damaged | missing | other
severity
description
latitude
longitude
photo_evidence
reported_at
status
sync_status
```

## Planned Phases

### Phase 1: Foundation and Staff Authentication

Status: complete.

- Review web design files.
- Create Android Flutter scaffold.
- Establish shared theme tokens.
- Create `MONITORING_STAFF` domain model.
- Build native login and staff sign-up screens.
- Add local validation and smoke test.

Review gate: confirm visual fidelity, field names, staff types, and backend contract assumptions.

### Phase 2: Frontend Shell and Secure Authentication Integration

Frontend shell status: complete. Secure authentication integration remains pending.

Frontend work completed:

- Add the shared bottom navigation and center scan action.
- Translate Events, Map, Scanner, Alerts, and Profile reference surfaces.
- Add manual verification draft fields for tree tag, DBH, and crown dimension.
- Add local navigation coverage in the widget test.

Remaining secure authentication work:

- Define API request/response DTOs.
- Add an authentication data source and repository.
- Hash passwords only where the agreed security architecture requires it; normally the server owns password hashing.
- Add secure token storage using an approved Android secure-storage solution.
- Add session restoration, logout, expiry handling, and route protection.
- Add loading, error, retry, and offline states.
- Add tests for valid login, invalid credentials, disabled staff, expired session, and signup failure.

Do not proceed without a confirmed API base URL, authentication payload, response payload, token strategy, and staff authorization rules.

### Phase 3: Field Verification

Real map surface status: complete (Phase 3 map port).

- Replace the synthetic grid map with a real interactive Leaflet-style map (`flutter_map` + `latlong2`).
- Port the admin portal's 23 `TRE-*` records, zone frames, statuses, and colors into the Map tab (OSM default, Esri satellite toggle, zone chips, status filters, GPS/recenter, bottom-sheet details linked to verification and incident reporting).
- Verify `flutter analyze`, `flutter test`, and `flutter build apk --debug` gates for the map port.

Field verification frontend preview status: complete for the initial manual-entry and selected-tree flow. Real data, camera/NFC, GPS, and draft persistence remain pending.

- Build the tree lookup or scan entry point.
- Mirror `TREE_RECORD` attributes in a mobile data-collection form.
- Add DBH, crown dimension, plant status, notes, GPS, and photo evidence.
- Add automated OpenCV/camera measurement behind an interface.
- Provide a manual measurement fallback whenever automation is unavailable or uncertain.
- Persist drafts locally so a field worker can work offline.
- Add submit and retry behavior with clear verification status.

The camera and OpenCV implementation must not block manual entry. The UI should show the source of a measurement: automated, manual, or corrected manually.

### Phase 4: Incident Reporting

Frontend preview status: complete for the initial linked-tree incident form. Backend submission, evidence capture, location capture, and queue state remain pending.

- Add damaged-tree and missing-tree reporting.
- Link every report to the authenticated `staff_id`.
- Link reports to a tree when a tree identifier is available.
- Capture evidence, location, severity, description, and timestamps.
- Support draft, queued, submitted, and failed states.
- Add validation and duplicate-submit protection.

### Phase 5: Synchronization Dashboard

Frontend preview status: complete for the initial status and audit-history presentation. Real-time transport, server feedback, conflict handling, and durable local queue remain pending.

- Show verification feedback and status updates.
- Show pending, syncing, synced, failed, and conflict records.
- Show audit history for each tree and incident.
- Display last successful synchronization time and current connectivity.
- Add pull-to-refresh and retry controls.
- Preserve local records until the server confirms synchronization.

The dashboard must distinguish local draft state from server audit state. Never silently discard a local field report.

### Phase 6: Hardening and Release

- Add unit, widget, integration, and device tests.
- Verify Android permissions for camera, location, and notifications only when needed.
- Add structured logging without credentials or sensitive evidence leakage.
- Review secure storage, certificate/network configuration, and release signing.
- Test slow network, offline mode, permission denial, app restart, duplicate submission, and conflict resolution.
- Produce an Android release APK/AAB and deployment checklist.

## Data and Security Rules

- Never log passwords, password hashes, access tokens, refresh tokens, or private evidence URLs.
- Never store plaintext passwords in the app.
- Use server-issued identity and authorization claims for staff access decisions.
- Treat all client input as untrusted, including GPS, measurements, status values, and staff type.
- Use explicit units for measurements and preserve measurement provenance.
- Include idempotency or client-generated request IDs for retryable submissions.
- Keep timestamps timezone-aware and document the server/client timezone contract.
- Ask for Android permissions at the point of use and handle denial gracefully.
- Retain unsynchronized field data safely until the server confirms receipt.

## Testing and Validation Commands

From the repository root:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Before a release build:

```powershell
flutter build appbundle --release
```

When changing a feature, add or update focused tests before broadening the implementation. Run the analyzer and relevant tests after every phase gate.

## AI Handoff Instructions

When continuing this project:

1. Read this README and the progress logs (`PHASE_1_PROGRESS.md`, `PHASE_2_PROGRESS.md`, `PHASE_3_PROGRESS.md`).
2. Inspect the current files before editing; user or formatter changes may be present.
3. Confirm which phase the user wants to start or review.
4. Work in one phase only and stop at the review gate.
5. Preserve the existing theme and mobile-first visual language unless the user requests a design change.
6. Do not invent backend endpoints, credentials, schema fields, or OpenCV behavior. Ask for the missing contract or leave a clearly marked adapter boundary.
7. Keep Android as the only target platform.
8. Update the phase progress log and this README when architecture or contracts change.
9. Run `flutter analyze` and the narrowest relevant tests before reporting completion.

## Current Next Action

The next recommended task is to confirm the backend contracts: obtain the authentication endpoint, request and response examples, token/session behavior, and the authoritative `MONITORING_STAFF` and `TREE_RECORD` schemas. With those confirmed, wire the Map tab's inventory and statuses to the backend tree records endpoint (replacing the local admin-portal seed) and integrate secure authentication for Phase 2. The typed domain contracts can then receive DTO mappers without changing the screens.

# ecotrace

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
