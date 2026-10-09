# EcoTrace

EcoTrace is an Android Flutter application for environmental tree monitoring,
field verification, incident reporting, events, alerts, and audit feedback.
The companion admin web app manages the authoritative operational data and
review workflow.

> ### Documentation
> [`DOCUMENTATION.md`](DOCUMENTATION.md) is the single source of truth for the
> admin web app/backend handoff and the Flutter application.

## Quick facts

| | |
|---|---|
| Mobile platform | Android |
| Mobile stack | Flutter · Material 3 · `flutter_map` · `geolocator` · `http` · `image_picker` · `shared_preferences` |
| Mobile state | REST authentication plus optional JWT/profile session persistence |
| Admin reference | `C:\xampp\htdocs\projects\ecotrace_admin` |
| Database reference | `docs/schema_v2.sql` |

## Current gates

```powershell
cd C:\flutter_workspace\ecotrace
flutter pub get
flutter analyze      # clean
flutter test         # 87 passed; 2 login-widget tests require HTTP mocking
```

## Mobile application

The app launches through splash, restores an opted-in session when available,
and otherwise shows staff login. Login can register/authenticate through the
configured API. “Keep me signed in” is unchecked by default; when selected,
only the JWT and non-sensitive profile fields are stored. Passwords are never
persisted. Sign-out clears the stored session and removes authenticated routes.

The current UI includes events, a 23-tree campus map, routing, field
verification, incident reporting, alerts, profile, connectivity feedback, and
a field-progress dashboard. Verification records and event participation remain
local preview state until their API synchronization is implemented.

## Admin web app and backend

The admin web app is maintained separately at `C:\xampp\htdocs\projects\ecotrace_admin`.
It owns administrative review and the authoritative tree/site inventory. This
Flutter repository contains the integration contract and database reference,
not the admin web app source. Use `docs/phpmyadmin_schema_setup.md` to create a
fresh test database from `docs/schema_v2.sql`; do not import it into a legacy or
production database without a staged migration.

## Known limitations

The proximity gate is currently disabled for UI testing. The two failing login
widget tests still depend on a real HTTP request and should be converted to
mocked-client tests; they are not evidence of a backend failure. See
`DOCUMENTATION.md` for the complete queue and verification notes.

[`ai_instructions.md`](ai_instructions.md) is binding for repository work. Do
not commit or push changes automatically.