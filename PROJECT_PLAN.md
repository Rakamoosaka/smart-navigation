# SDU Campus Assistant — Product and Technical Plan

## 1. Purpose

SDU Campus Assistant is a map-first, role-based mobile app for students, teachers, administrators, and visitors. Its interactive SDU campus map is the home screen and central way to discover locations, services, routes, and campus information. It also provides role-relevant information and a way to report incorrect information.

The one-shot delivery is a working Flutter application with a FastAPI backend, PostgreSQL database, real role-based authorization, API documentation, and an inspectable database.

## 2. Product roles

| Role | Access |
|---|---|
| Guest | Public search, services, map, routes, campus assistant, announcements |
| Student | Guest features plus personal timetable, next class, favourites, accessibility preferences, and reports |
| Teacher | Guest features plus teaching schedule, assigned rooms, office hours, and reports |
| Administrator | Manage users/roles, locations, services, routes, announcements, reports, and analytics |

A user may hold more than one role. For example, an administrator can also be a teacher.

## 3. Registration and role identification

### Registration flow

1. User chooses **Create account** and enters a 9-digit SDU ID, full name, password, and password confirmation.
2. Backend validates the ID and password, hashes the password, and creates the account.
3. On later visits, the user signs in with the SDU ID and password.
4. Backend determines the role from its role rules and role overrides.
5. Backend issues a JWT access token.
6. Flutter stores the token securely and opens the correct dashboard.

Guest access is separate:

1. User taps **Continue as Guest**.
2. Backend creates a temporary anonymous guest session/token.
3. Guest can access public endpoints only.

### Initial role rule for the project

The actual SDU number rules are not yet available, so the system must not pretend it can reliably infer faculty or staff status from every number.

For the project demo:

- Any valid 9-digit SDU ID defaults to **Student**.
- A `role_overrides` table assigns selected demonstration IDs to **Teacher** or **Administrator**.
- Example seeded demo records:
  - `240103049` → Student (Yerassyl)
  - `240103050` → Student (Daulet)
  - `240103051` → Student (Omar)
  - `240103052` → Student (Aitore)
  - `240103053` → Student (Aidyn)
  - `240000001` → Teacher
  - `240000002` → Administrator

All seeded accounts use `Campus123!` for the classroom demonstration. Passwords are stored only as salted PBKDF2 hashes.

Role assignment is fully local to the project database. If the team later defines more number-pattern rules, they can be added to the role rule configuration without changing the Flutter screens.

## 4. Complete feature scope

### A. Access and profile

- Student, teacher, administrator, and guest entry.
- SDU ID/password registration and login.
- JWT session and logout.
- Role-specific dashboard.
- Registered-user profile, faculty, saved locations, and saved accessibility preferences.

### B. Search and locations

- Map-first search: the search bar stays on the campus map and each result zooms to and highlights its pin.
- Search by room code, location name, service, category, and aliases.
- Search facilities: printers, cafeterias, ATMs, restrooms, parking, library, offices, laboratories, security, and medical point.
- Tolerant search: spelling normalization, aliases, and suggestion list.
- Location details: building, floor, opening hours, contact details, accessibility information, route button, and a registered-user-only save button.
- Library and office/service directory.

### C. Map and navigation

- Interactive campus map based on the supplied SDU map artwork. It has tappable overlays for Blocks A–H, entrances, facilities, and service icons.
- Map-first home: all roles arrive at the map after authentication or guest entry; role-specific information appears as quick actions and map panels rather than replacing the map.
- Tapping a block, service marker, route, or search result opens a location bottom sheet; it can expand to full details.
- Map pins and filtering for rooms, faculties, offices, laboratories, library, food, printers, ATMs, restrooms, parking, security, medical point, Wi-Fi, and entrances.
- Search result highlighting, map zoom/pan, selected-place state, and saved-place pins.
- Start/destination selector.
- Route is drawn as a highlighted line/overlay on the supplied map, with a selected start, destination, entrances, and route segments.
- Walking distance and estimated walking time.
- Step-by-step route instructions.
- Accessible route option: avoid stairs, prefer elevators, accessible entrance.
- Seeded campus routes for the project; live indoor positioning is future scope.

### D. Personal academic guidance

- Student next class, course, room, time, and route action.
- Student timetable.
- Teacher teaching schedule, assigned classroom, and office hours.
- Favourite locations.

### E. Smart assistant

- Natural-language-style campus questions using intent and keyword rules:
  - “Where can I park?”
  - “Where is Room 317?”
  - “I need a printer.”
  - “Where can I eat?”
- Clarification when multiple locations match.
- Service recommendations based on category, opening hours, distance, and accessibility preferences.
- No paid LLM is required for the first delivery.

### F. Announcements and reporting

- Public announcements and campus events.
- Report incorrect service/location information.
- Report status: New, Under Review, Resolved.
- Student and teacher report history.

### G. Administration and analytics

- Manage locations, services, contacts, opening hours, and routes.
- Manage announcements/events.
- Review and resolve reports.
- Assign/revoke user roles.
- Record searches and show popular searches/categories.

## 5. User-story coverage

| User-story group | Delivery |
|---|---|
| Login, guest access, favourites, accessibility preferences | Included |
| Classroom/facility search, details, tolerant search | Included |
| Next-class guidance | Included |
| Natural-language questions, clarification, recommendations | Included with rule-based assistant |
| Route selection, steps, accessibility, distance/time | Included with seeded routes |
| Library/services/office details, announcements | Included |
| Reports, admin management, analytics | Included |

## 6. Pages

### Entry

1. Splash screen
2. Welcome screen — **Continue as Student** or **Continue as Guest**
3. SDU ID/password login and registration

### Core map experience (the primary app)

4. **Interactive campus map home** — default screen for guests, students, and teachers. It contains search, category filters, tappable pins, selected-route overlay, current role, and shortcut actions.
5. Search results bottom sheet — results remain connected to the map; choosing one highlights and zooms to it.
6. Location bottom sheet / full location details — building, floor, hours, contact, accessibility, save, and route actions.
7. Route planner and step-by-step navigation — choose start/destination, view map route, distance/time, accessible option, and steps.
8. Campus assistant overlay/chat — answers campus questions and can focus the map, select a service, or begin a route.
9. Announcements/events panel — campus updates, including location-linked announcements that can open on the map.

### Personal and role-specific supporting screens

10. Student panel — next class, timetable, class-to-map route action, favourites, accessibility preferences, reports, and profile.
11. Teacher panel — teaching schedule, assigned rooms, office hours, reports, and profile.
12. Guest account panel — public-feature summary, login/register prompts, and end-session action. No favourites, saved preferences, schedules, or reporting.

### Administration

13. Admin dashboard
14. Location/service/map-marker and route management
15. User and role management
16. Announcement/event management
17. Report review
18. Search analytics

The map replaces separate guest/student/teacher dashboards and a stand-alone services directory as the main navigation surface. Services, schedule destinations, favourites, announcements, and assistant answers open as map states, panels, or sheets.

## 7. Final technical stack

| Layer | Technology | Reason |
|---|---|---|
| Mobile app | Flutter / Dart | Android and iOS from one codebase |
| State management | Riverpod | Predictable, testable application state |
| Routing | GoRouter | Guarded role-based navigation |
| HTTP client | Dio | JWT interceptors, retries, error handling |
| Secure storage | flutter_secure_storage | Store JWT token securely |
| Map | Flutter `InteractiveViewer` / custom `CustomPainter` overlays | The supplied campus-map artwork remains visually recognizable while tappable pins, zones, and route lines are placed precisely over it; no external map billing or live geocoding is needed |
| Backend | FastAPI / Python | Fast development, typed API, automatic Swagger docs |
| ORM | SQLModel | Simple FastAPI-friendly data models |
| Database | PostgreSQL | Production-style relational database |
| Migrations | Alembic | Versioned database schema |
| Local environment | Docker Compose | One command starts API, database, and admin viewer |
| Database viewer | pgAdmin | Visible teacher-facing database interface |
| API docs | FastAPI Swagger at `/docs` | Demonstrable API contract |
| Backend testing | Pytest + FastAPI TestClient | API and permission tests |
| Mobile testing | Flutter widget/integration tests | UI and role-flow tests |

### Environment diagram

```text
Flutter mobile app
   ↓ HTTPS in production / localhost in development
FastAPI API + JWT/RBAC
   ↓ SQLModel
PostgreSQL
   ↕
pgAdmin database viewer

Docker Compose starts: api + postgres + pgadmin
```

The app and API run locally for the course demonstration.

## 8. Database model

```text
users
roles
user_roles
guest_sessions
refresh_tokens
accessibility_preferences

locations
services
map_markers
map_zones
routes
route_steps

classes
teaching_assignments
office_hours
favorites

announcements
events
inaccuracy_reports
search_logs
role_overrides
```

Important fields:

- `users`: id, full_name, internal identity key, faculty, status, created_at.
- `auth_accounts`: id, user_id, SDU ID, password hash, created_at.
- `roles`: id, name (`guest`, `student`, `teacher`, `admin`).
- `user_roles`: user_id, role_id.
- `role_overrides`: SDU ID, role_id, reason.
- `locations`: name, category, building, floor, coordinates, contact details, opening hours, accessibility notes.
- `map_markers`: location_id, x/y position expressed as percentages of the map artwork, icon/category, and label.
- `map_zones`: block or facility area, polygon points expressed as percentages of the map artwork, location_id, and selectable state.
- `routes`: start location, destination, distance, duration, accessible flag.
- `route_steps`: route_id, step order, instruction.
- `search_logs`: query, user/session, selected result, timestamp.

## 9. API design

### Authentication and identity

```text
POST /auth/register
POST /auth/login
POST /auth/guest
POST /auth/refresh
POST /auth/logout
GET  /users/me
```

### Public campus information

```text
GET /locations
GET /locations/{id}
GET /search?q=
GET /services
GET /announcements
GET /events
GET /routes?from=&to=&accessible=
POST /assistant/query
```

### Student and teacher endpoints

```text
GET    /students/me/timetable
GET    /students/me/next-class
GET    /users/me/favorites
POST   /users/me/favorites/{location_id}
DELETE /users/me/favorites/{location_id}
GET    /teachers/me/schedule
GET    /teachers/me/office-hours
POST   /reports
GET    /reports/me
```

### Administrator endpoints

```text
GET    /admin/users
PUT    /admin/users/{id}/roles
POST   /admin/locations
PUT    /admin/locations/{id}
POST   /admin/services
PUT    /admin/services/{id}
POST   /admin/routes
POST   /admin/announcements
PUT    /admin/announcements/{id}
GET    /admin/reports
PUT    /admin/reports/{id}
GET    /admin/analytics/popular-searches
```

FastAPI dependencies enforce permissions, for example `require_role('admin')`.

## 10. Role-permission matrix

| Capability | Guest | Student | Teacher | Admin |
|---|:---:|:---:|:---:|:---:|
| Search, services, public map, routes | Yes | Yes | Yes | Yes |
| Accessible route option | Yes | Yes | Yes | Yes |
| Saved accessibility preference | No | Yes | Yes | Yes |
| Favourites | No | Yes | Yes | Yes |
| Personal timetable/next class | No | Yes | No | Optional |
| Teaching schedule/office hours | No | No | Yes | Manage all |
| Submit report | No | Yes | Yes | Yes |
| Announcements/events | View | View | View | Manage |
| Manage locations/services/routes | No | No | No | Yes |
| Resolve reports | No | No | No | Yes |
| Manage roles | No | No | No | Yes |
| View analytics | No | No | No | Yes |

## 11. Definition of done

The project is ready for demonstration when:

1. A valid 9-digit SDU ID can be registered with a password, logged in, and assigned the correct role.
2. Guest entry works without an institutional account.
3. Flutter opens every guest, student, and teacher on the interactive campus map.
4. The supplied SDU map has tappable blocks, facilities, entrances, and service pins; selecting one opens its details.
5. Search finds rooms, services, and facilities, including aliases, then zooms to and highlights the result on the map.
6. A location details sheet shows building, floor, hours, contact, and accessibility information.
7. A user can view a seeded, highlighted map route with distance, time, and steps.
8. An accessibility preference changes the available route.
9. Student and teacher schedules show different role-specific data and can open a destination route on the map.
10. The assistant answers seeded campus-intent questions, asks for clarification when appropriate, and can focus a location or service on the map.
11. A user can submit an inaccuracy report.
12. An administrator can manage map-linked data and resolve the report.
13. FastAPI Swagger docs and pgAdmin show the working API and PostgreSQL data.
14. Backend permission tests and Flutter role-flow tests pass.

## 12. Future scope

- Imported official timetable and directory data.
- Live GPS/indoor positioning.
- Live shuttle and occupancy data.
- Push notifications.
- Multi-language support.
- LLM-powered conversational assistant.
