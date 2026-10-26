# EcoTrace

EcoTrace is an Android Flutter application for environmental tree monitoring,
field verification, incident reporting, events, alerts, and audit feedback.
The companion admin web app manages the authoritative operational data and
review workflow.

> ### Documentation
> [`DOCUMENTATION.md`](DOCUMENTATION.md) is the single source of truth for the
> admin web app/backend handoff and the Flutter application.
>
> **Updated 2026-10-16:** Authenticated event participation and joined-event synchronization are implemented across the Flutter app and Node/MariaDB API. Backend connection guides are available in the admin portal at
> `C:\xampp\htdocs\projects\ecotrace_admin\SERVER_STARTUP_AND_FLUTTER_CONNECTION.md`

## Quick facts

| | |
|---|---|
| Mobile platform | Android |
| Mobile stack | Flutter · Material 3 · `flutter_map` · `geolocator` · `http` · `image_picker` · `shared_preferences` |
| Mobile state | REST authentication plus optional JWT/profile session persistence |
| Admin reference | `C:\xampp\htdocs\projects\ecotrace_admin` |
| Database reference | `docs/schema_v2.sql` |
| Backend API | Node.js Express on port 3000 |
| Backend Database | `ecotrace_db` (or `ecotrace_v2_test`) |

## Current gates

```powershell
cd C:\flutter_workspace\ecotrace
flutter pub get
flutter analyze      # clean
flutter test         # targeted tests pass; full suite retains known shell/connectivity pumpAndSettle timeouts
```

## Mobile application

The app launches through splash, restores an opted-in session when available,
and otherwise shows staff login. Login can register/authenticate through the
configured API. “Keep me signed in” is unchecked by default; when selected,
only the JWT and non-sensitive profile fields are stored. Passwords are never
persisted. Sign-out clears the stored session and removes authenticated routes.

The current UI includes events, a 23-tree campus map, routing, field
verification, incident reporting, alerts, profile, connectivity feedback, and
a field-progress dashboard. Authenticated users can join and leave events; the
app loads and caches joined-event state, updates the dashboard/event filters,
and refreshes authenticated alerts after participation. Verification records
and tree-progress aggregation remain outside the current synchronization scope.

## Admin web app and backend

The admin web app is maintained separately at `C:\xampp\htdocs\projects\ecotrace_admin`.
It owns administrative review and the authoritative tree/site inventory. This
Flutter repository contains the integration contract and database reference,
not the admin web app source. Use `docs/phpmyadmin_schema_setup.md` to create a
fresh test database from `docs/schema_v2.sql`; do not import it into a legacy or
production database without a staged migration.

### Connecting to Backend API

**Backend Setup:**
1. Navigate to: `C:\xampp\htdocs\projects\ecotrace_admin\server`
2. Start server: `npm run dev` (runs on port 3000)
3. Ensure XAMPP MySQL is running

**Flutter Configuration:**
Edit `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android Emulator:
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // For Physical Device (replace with your PC's IP):
  // static const String baseUrl = 'http://192.168.1.42:3000/api';
}
```

**Find your PC's IP:**
- Windows: `ipconfig` → Look for IPv4 Address (192.168.x.x)
- Mac/Linux: `ifconfig` → Look for inet address

**Troubleshooting:**
See `C:\xampp\htdocs\projects\ecotrace_admin\SERVER_STARTUP_AND_FLUTTER_CONNECTION.md` for:
- Complete connection setup guide
- Firewall configuration
- Network troubleshooting
- Common error solutions

## Known limitations

The proximity gate is currently disabled for UI testing. The two failing login
widget tests still depend on a real HTTP request and should be converted to
mocked-client tests; they are not evidence of a backend failure. See
`DOCUMENTATION.md` for the complete queue and verification notes.

[`ai_instructions.md`](ai_instructions.md) is binding for repository work. Do
not commit or push changes automatically.

---

**Last Updated:** 2026-10-16