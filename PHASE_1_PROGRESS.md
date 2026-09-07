# EcoTrace Phase 1 Progress

## Completed

- Created a Flutter Android-only project scaffold in `c:/flutter_workspace/ecotrace`.
- Added a feature-first foundation under `lib/core` and `lib/features/auth`.
- Translated the reference login tokens: forest green, lemon yellow, pale green canvas, white fields, rounded controls, and the compact mobile layout.
- Added the `MonitoringStaff` domain model with `staffId`, `staffNumber`, `passwordHash`, and `StaffType` values for intern, paid volunteer, and staff.
- Built the native staff authentication screen with login and staff sign-up modes.
- Added local form validation, password visibility control, staff type selection, and review-only submit feedback.
- Updated the generated widget test to verify the EcoTrace authentication entry screen.

## Current State

Authentication is currently a UI and validation slice. No credentials are stored, hashed, or sent over a network yet. The submit action intentionally shows local feedback until the API and secure token-storage contract are supplied.

## Review Checklist

1. Run `flutter run` with an Android emulator or connected device.
2. Compare the header, tab treatment, spacing, field styling, and colors with `C:/Users/USER/Desktop/adi/New folder/login.html`.
3. Test both Login and Staff sign up modes.
4. Confirm that staff number, password length, and password confirmation validation match the intended backend rules.
5. Confirm the accepted `staff_type` values and the API shape before Phase 2.

## Next Phase Candidate

Connect the authentication repository to the agreed backend, add secure session persistence, and route authenticated staff to the field verification shell.