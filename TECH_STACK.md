# EcoTrace Technology Stack

This document describes the confirmed technology stack for the EcoTrace mobile application, admin web application, and supporting REST API.

## System overview

EcoTrace is composed of three connected parts:

1. **EcoTrace mobile application** — an Android application used for field monitoring, tree verification, incident reporting, events, alerts, and field progress.
2. **EcoTrace admin web application** — a browser-based React portal used for administrative review, tree inventory management, analytics, submissions, events, and map operations.
3. **EcoTrace REST API** — a Node.js service that provides authentication and database-backed application data to the mobile and web clients.

The admin web application and API are maintained in the separate project at `C:\xampp\htdocs\projects\ecotrace_admin`.

## Mobile application

| Area | Technology |
|---|---|
| Framework | Flutter `>=3.44.0` |
| Primary language | Dart `>=3.13.0 <4.0.0` |
| UI system | Flutter Material 3 and Cupertino icon support |
| Supported platform | Android |
| Maps | `flutter_map` with `latlong2` coordinate support |
| Location services | `geolocator` |
| Networking | Dart `http` package |
| Image capture | `image_picker` |
| Local persistence | `shared_preferences` |
| Connectivity monitoring | `connectivity_plus` plus HTTP reachability probing |
| Static analysis and linting | `flutter_lints` |
| Testing | `flutter_test` |
| Android build system | Gradle Kotlin DSL (`.gradle.kts`) with the Flutter Gradle plugin |
| Android native toolchain | Java 17 and Kotlin JVM target 17 |

### Mobile dependencies

The direct application dependencies declared in `pubspec.yaml` are:

- `cupertino_icons`
- `connectivity_plus`
- `flutter_map`
- `latlong2`
- `http`
- `geolocator`
- `image_picker`
- `shared_preferences`

### Mobile architecture notes

- The application uses Flutter widgets and Dart application code rather than a separate native Android UI layer.
- REST authentication uses the shared API. When the user opts in to remain signed in, the app stores the JWT and non-sensitive profile information in `shared_preferences`; passwords are not stored.
- The mobile application currently targets Android. iOS, web, and desktop flows are outside the confirmed product scope.
- Images and branding assets are bundled with the Flutter application.

## Admin web application

| Area | Technology |
|---|---|
| UI framework | React `19.0.0` |
| Primary language | JavaScript with JSX |
| Type documentation | JSDoc and `jsconfig.json` editor support |
| TypeScript | Not used; there is no TypeScript compiler or `tsc` step |
| Build tool and dev server | Vite `8.0.0` |
| React integration | `@vitejs/plugin-react` |
| Styling | Tailwind CSS `4.0.0` with `@tailwindcss/vite` |
| Interactive maps | Leaflet `1.9.4` and React Leaflet `5.0.0` |
| Charts | Recharts `3.10.1` |
| Module format | ECMAScript modules (`type: module`) |
| Runtime requirement | Node.js `>=20.19.0` according to `package.json` |
| Package manager | npm with `package-lock.json` |
| Formatting | `oxfmt` |
| Testing | Vitest `5.0.2` with JSDOM |

### Web application structure

- `src/` contains the React application and shared client-side utilities.
- `src/components/` contains reusable UI components and feature modules.
- `src/lib/` contains the REST client, state/store logic, tree data helpers, map helpers, and tests.
- Vite serves the UI on port `8443` by default.
- In development and preview, Vite proxies `/api` requests to the API at `http://localhost:3000`.
- The project can render mock/in-memory data when live API integration is disabled.
- The web map is implemented with Leaflet through React Leaflet.


## REST API

| Area | Technology |
|---|---|
| Runtime | Node.js `>=20` |
| Framework | Express `5.1.0` |
| Language | JavaScript using ECMAScript modules |
| Database driver | `mysql2` promise API |
| Database validation | `zod` |
| Authentication tokens | JSON Web Tokens via `jsonwebtoken` |
| Password hashing | `bcryptjs` |
| Configuration | `dotenv` environment variables |
| Cross-origin support | `cors` |
| API testing | Node.js built-in test runner (`node --test`) |
| API development mode | Node `--watch` |

### API responsibilities

- Authentication endpoints for registration, login, and profile access.
- JWT-based authenticated requests.
- Database health/liveness checks.
- Administrative and mobile data access through REST endpoints.
- Database migrations and rebuild scripts maintained under the API project.

The API listens on port `3000` by default and is located at:

```text
C:\xampp\htdocs\projects\ecotrace_admin\server
```

## Database and local infrastructure

| Area | Technology |
|---|---|
| Relational database | MariaDB |
| Local database distribution | XAMPP-bundled MariaDB |
| Default database port | `3306` |
| Default database name | `ecotrace_db` |
| Database access | Node.js `mysql2/promise` connection pool |
| Database definition and setup | SQL migrations and schema documentation |
| Database administration | phpMyAdmin through XAMPP |

The API reads database connection values from environment variables such as `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME`. Database credentials are server-side configuration and are not bundled into the browser application.

## Client-to-server communication

- **Mobile app → API:** the Flutter app calls the configured REST base URL, normally using `/api` endpoints on port `3000`. Android emulators can reach the host machine through `10.0.2.2`; physical devices use the host computer's LAN address.
- **Admin web app → API:** the browser calls `/api` through the Vite development proxy, avoiding cross-origin requests during local development.
- **Authentication:** the API issues JWTs. Authenticated clients send the token as a Bearer token. `EventClient` uses it for joined-event, join, and leave requests; `AlertsScreen` uses it for the published alert feed.
- **Configuration:** API URLs, ports, database settings, JWT settings, and CORS settings are controlled through environment variables or client configuration files.

## Quality and verification tools

### Mobile commands

```powershell
cd C:\flutter_workspace\ecotrace
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

### Web commands

```powershell
cd C:\xampp\htdocs\projects\ecotrace_admin
npm install
npm run test
npm run build
npm run verify
```

### API commands

```powershell
cd C:\xampp\htdocs\projects\ecotrace_admin\server
npm install
npm run migrate
npm test
npm run dev
```

## Repository and scope notes

- The mobile application and its database/integration reference documentation are in `C:\flutter_workspace\ecotrace`.
- The admin UI and REST API are in `C:\xampp\htdocs\projects\ecotrace_admin`.
- The `.figma/` directory in the admin project is part of the Vite configuration and must remain available unless that configuration is refactored.
- This document records technologies confirmed by the current project configuration; it does not list planned or unimplemented services.

_Last reviewed: 2026-10-16._

