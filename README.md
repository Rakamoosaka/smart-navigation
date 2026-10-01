# SDU Campus Assistant

A map-first Flutter mobile app with a FastAPI backend and PostgreSQL database. The supplied SDU campus plan is interactive: users can search, tap location pins, view details, save places, ask the assistant, and display seeded walking routes.

## Included demo flows

- Guest entry without registration.
- SDU ID/password registration and login with automatic Student, Teacher, or Administrator role.
- Interactive, zoomable SDU map with searchable pins and category filters.
- Location details, favourites, accessible route preference, walking time, and route steps.
- Student next class and timetable.
- Teacher teaching schedule and office details.
- Rule-based campus assistant with clarification and map actions.
- Announcements linked to map locations.
- Inaccuracy reports.
- Administrator location, route, role, announcement, report, and analytics views.
- FastAPI Swagger documentation and PostgreSQL/pgAdmin database inspection.

## Demo accounts

| Role | SDU ID |
|---|---|
| Student (Yerassyl) | `240103049` |
| Student (Daulet) | `240103050` |
| Student (Omar) | `240103051` |
| Student (Aitore) | `240103052` |
| Student (Aidyn) | `240103053` |
| Teacher | `240000001` |
| Administrator | `240000002` |

All seeded accounts use the password `Campus123!`. New 9-digit IDs can be registered from the app and receive the Student role by default.

## Fastest local demonstration

Start the lightweight SQLite-backed API:

```bash
cd ~/University/Project\ Management
make backend-local
```

In a second terminal, start the iOS Simulator and Flutter app:

```bash
open -a Simulator
cd ~/University/Project\ Management
flutter run
```

Open API documentation at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs). The local database is created as `sdu_campus.db`.

The Flutter UI contains seeded fallback data, so the map and role demonstration still open if the API is stopped. When the API is running, login and guest sessions are persisted and JWT tokens are stored in secure device storage.

With the API running, map locations, announcements, registered-user favourites, accessibility preferences, and inaccuracy reports are loaded from or written to PostgreSQL. Restarting the app restores the saved session and opens the correct role directly on the map.

## PostgreSQL + pgAdmin demonstration

```bash
docker compose up --build -d
```

- API and Swagger: `http://127.0.0.1:8000/docs`
- pgAdmin: `http://127.0.0.1:5050`
- pgAdmin login: `admin@sdu.edu.kz` / `admin`
- Register the database server with host `database`, port `5432`, database `sdu_campus`, username `sdu`, password `sdu_demo_password`.

Stop the services with `docker compose down`. Data remains in the named PostgreSQL volume.

## Tests

```bash
make test
```

## Project documentation

- [Product and technical plan](PROJECT_PLAN.md)
- [Design system](design-system.md)
- [Database schema](database-schema.md)
- [Database ERD image](docs/database-erd.svg)
