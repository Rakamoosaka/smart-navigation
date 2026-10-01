from __future__ import annotations

import base64
import hashlib
import hmac
import os
import re
import secrets
from datetime import datetime, timedelta, timezone
from typing import Annotated
from uuid import uuid4

import jwt
from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import or_
from sqlmodel import Field, Session, SQLModel, create_engine, select

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sdu_campus.db")
JWT_SECRET = os.getenv("JWT_SECRET", "sdu-campus-course-demo-secret")
engine = create_engine(DATABASE_URL, echo=False, pool_pre_ping=True)
security = HTTPBearer(auto_error=False)


class User(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    full_name: str
    email: str = Field(index=True, unique=True)
    role: str = Field(default="student", index=True)
    faculty: str = "SDU"
    active: bool = True
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class AuthAccount(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    sdu_id: str = Field(index=True, unique=True)
    password_hash: str
    user_id: int = Field(index=True, unique=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class GuestSession(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    session_key: str = Field(index=True, unique=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class RoleOverride(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    email: str = Field(index=True, unique=True)
    role: str
    reason: str = "Seeded course demonstration role"


class Preference(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(index=True)
    accessible_routes: bool = False


class Location(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    category: str = Field(index=True)
    block: str = Field(index=True)
    floor: str
    x: float
    y: float
    opening_hours: str = "08:00–18:00"
    contact: str = "+7 727 307 95 65"
    accessible: bool = True
    aliases: str = ""


class Route(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    start_location_id: int
    destination_location_id: int
    distance_m: int
    duration_min: int
    accessible: bool = False


class RouteStep(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    route_id: int = Field(index=True)
    step_order: int
    instruction: str


class Favorite(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(index=True)
    location_id: int = Field(index=True)


class CampusClass(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    owner_email: str = Field(index=True)
    course: str
    room: str
    starts_at: str
    location_id: int
    kind: str = "student"


class Announcement(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    title: str
    body: str
    published_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    location_id: int | None = None


class InaccuracyReport(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    author: str
    location_id: int | None = None
    message: str
    status: str = Field(default="new", index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class SearchLog(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    actor: str
    query: str = Field(index=True)
    selected_location_id: int | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class LoginRequest(BaseModel):
    sdu_id: str
    password: str


class RegisterRequest(BaseModel):
    sdu_id: str
    full_name: str
    password: str


class ReportRequest(BaseModel):
    message: str
    location_id: int | None = None


class AssistantRequest(BaseModel):
    question: str


class RoleRequest(BaseModel):
    role: str


class StatusRequest(BaseModel):
    status: str


class PreferenceRequest(BaseModel):
    accessible_routes: bool


class LocationRequest(BaseModel):
    name: str
    category: str
    block: str
    floor: str
    x: float
    y: float
    opening_hours: str = "08:00–18:00"
    contact: str = "+7 727 307 95 65"
    accessible: bool = True
    aliases: str = ""


def get_session():
    with Session(engine) as session:
        yield session


DbSession = Annotated[Session, Depends(get_session)]


def make_token(subject: str, role: str) -> str:
    payload = {"sub": subject, "role": role, "exp": datetime.now(timezone.utc) + timedelta(hours=12)}
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def normalize_sdu_id(value: str) -> str:
    sdu_id = value.strip()
    if not re.fullmatch(r"\d{9}", sdu_id):
        raise HTTPException(status_code=422, detail="Enter your 9-digit SDU ID")
    return sdu_id


def hash_password(password: str) -> str:
    if len(password) < 8:
        raise HTTPException(status_code=422, detail="Password must be at least 8 characters")
    iterations = 600_000
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, iterations)
    return "$".join([
        "pbkdf2-sha256",
        str(iterations),
        base64.urlsafe_b64encode(salt).decode(),
        base64.urlsafe_b64encode(digest).decode(),
    ])


def verify_password(password: str, encoded: str) -> bool:
    try:
        algorithm, raw_iterations, raw_salt, raw_digest = encoded.split("$", 3)
        if algorithm != "pbkdf2-sha256":
            return False
        salt = base64.urlsafe_b64decode(raw_salt.encode())
        expected = base64.urlsafe_b64decode(raw_digest.encode())
        actual = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, int(raw_iterations))
        return hmac.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def user_for_identity(identity: dict, session: Session) -> User | None:
    subject = identity["sub"]
    if re.fullmatch(r"\d{9}", subject):
        account = session.exec(select(AuthAccount).where(AuthAccount.sdu_id == subject)).first()
        return session.get(User, account.user_id) if account else None
    if "@" in subject:
        return session.exec(select(User).where(User.email == subject)).first()
    return None


def current_identity(credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)]) -> dict:
    if not credentials:
        raise HTTPException(status_code=401, detail="Authentication required")
    try:
        return jwt.decode(credentials.credentials, JWT_SECRET, algorithms=["HS256"])
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired token") from exc


Identity = Annotated[dict, Depends(current_identity)]


def admin_only(identity: Identity) -> dict:
    if identity.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Administrator role required")
    return identity


AdminIdentity = Annotated[dict, Depends(admin_only)]


DEMO_USERS = {
    "240103049": "Yerassyl",
    "240103050": "Daulet",
    "240103051": "Omar",
    "240103052": "Aitore",
    "240103053": "Aidyn",
    "240000001": "Dr. Ayan",
    "240000002": "Campus Admin",
}
DEMO_PASSWORD = "Campus123!"

LOCATION_SEEDS = [
    ("Main Entrance", "Entrance", "Block C", "Ground floor", .72, .76, "entrance c,main door"),
    ("Library", "Study", "Block B", "1st floor", .49, .88, "books,reading room"),
    ("Food Court", "Food", "Block F", "1st floor", .74, .33, "cafeteria,canteen,eat,coffee"),
    ("Room 317", "Classroom", "Block F", "3rd floor", .43, .38, "317,f317"),
    ("Student Service Centre", "Office", "Block D", "1st floor", .51, .61, "ssc,student office"),
    ("Medical Point", "Health", "Block H", "1st floor", .44, .18, "doctor,clinic,first aid"),
    ("Printer — Engineering", "Printer", "Block F", "2nd floor", .31, .34, "copy,printing"),
    ("Accessible Restroom", "Restroom", "Block E", "1st floor", .48, .47, "toilet,wc"),
    ("ATM", "Finance", "Block G", "1st floor", .26, .23, "cash,bank"),
    ("Parking Entrance", "Parking", "Block H", "Outside", .80, .15, "car park,park"),
    ("Teacher Office 215", "Office", "Block D", "2nd floor", .39, .57, "office hours,teacher"),
    ("Wi-Fi Lounge", "Service", "Block C", "1st floor", .62, .78, "internet,lounge"),
]


def seed_database() -> None:
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        if session.exec(select(RoleOverride)).first() is None:
            session.add_all([
                RoleOverride(email="240000001@sdu.edu.kz", role="teacher"),
                RoleOverride(email="240000002@sdu.edu.kz", role="admin"),
            ])
        for sdu_id, full_name in DEMO_USERS.items():
            email = f"{sdu_id}@sdu.edu.kz"
            role = "teacher" if sdu_id == "240000001" else "admin" if sdu_id == "240000002" else "student"
            user = session.exec(select(User).where(User.email == email)).first()
            if user is None:
                user = User(full_name=full_name, email=email, role=role)
                session.add(user)
                session.flush()
            else:
                user.role = role
            account = session.exec(select(AuthAccount).where(AuthAccount.sdu_id == sdu_id)).first()
            if account is None:
                session.add(AuthAccount(sdu_id=sdu_id, password_hash=hash_password(DEMO_PASSWORD), user_id=user.id))
        if session.exec(select(Location)).first() is None:
            for name, category, block, floor, x, y, aliases in LOCATION_SEEDS:
                hours = "08:00–22:00" if name == "Library" else "08:00–18:00"
                session.add(Location(name=name, category=category, block=block, floor=floor, x=x, y=y, aliases=aliases, opening_hours=hours))
        if session.exec(select(Announcement)).first() is None:
            session.add_all([
                Announcement(title="Library extended hours", body="Open until 22:00 during assessment week.", location_id=2),
                Announcement(title="Career fair", body="Meet employers in the main atrium on Friday at 11:00.", location_id=1),
                Announcement(title="Block F printer maintenance", body="Use the printer in Block D until 14:00.", location_id=7),
            ])
        if session.exec(select(CampusClass)).first() is None:
            for sdu_id in DEMO_USERS:
                email = f"{sdu_id}@sdu.edu.kz"
                session.add(CampusClass(owner_email=email, course="Project Management", room="317", starts_at="10:30", location_id=4, kind="teacher" if email == "240000001@sdu.edu.kz" else "student"))
        session.commit()


app = FastAPI(title="SDU Campus Assistant API", version="1.0.0", description="Course-project API for the map-first SDU campus assistant.")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.on_event("startup")
def startup() -> None:
    seed_database()


@app.get("/health", tags=["System"])
def health() -> dict:
    return {"status": "ok", "database": DATABASE_URL.split(":", 1)[0]}


@app.post("/auth/register", status_code=201, tags=["Authentication"])
def register(body: RegisterRequest, session: DbSession) -> dict:
    sdu_id = normalize_sdu_id(body.sdu_id)
    full_name = body.full_name.strip()
    if len(full_name) < 2:
        raise HTTPException(status_code=422, detail="Enter your full name")
    if session.exec(select(AuthAccount).where(AuthAccount.sdu_id == sdu_id)).first():
        raise HTTPException(status_code=409, detail="This SDU ID is already registered")
    email = f"{sdu_id}@sdu.edu.kz"
    override = session.exec(select(RoleOverride).where(RoleOverride.email == email)).first()
    role = override.role if override else "student"
    user = session.exec(select(User).where(User.email == email)).first()
    if user is None:
        user = User(full_name=full_name, email=email, role=role)
        session.add(user)
        session.flush()
    else:
        user.full_name = full_name
        user.role = role
    session.add(AuthAccount(sdu_id=sdu_id, password_hash=hash_password(body.password), user_id=user.id))
    session.commit()
    return {"access_token": make_token(sdu_id, role), "token_type": "bearer", "name": user.full_name, "sdu_id": sdu_id, "role": role}


@app.post("/auth/login", tags=["Authentication"])
def login(body: LoginRequest, session: DbSession) -> dict:
    sdu_id = normalize_sdu_id(body.sdu_id)
    account = session.exec(select(AuthAccount).where(AuthAccount.sdu_id == sdu_id)).first()
    if account is None or not verify_password(body.password, account.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect ID or password")
    user = session.get(User, account.user_id)
    if user is None or not user.active:
        raise HTTPException(status_code=403, detail="This account is unavailable")
    return {"access_token": make_token(sdu_id, user.role), "token_type": "bearer", "name": user.full_name, "sdu_id": sdu_id, "role": user.role}


@app.post("/auth/guest", tags=["Authentication"])
def guest(session: DbSession) -> dict:
    key = str(uuid4())
    session.add(GuestSession(session_key=key))
    session.commit()
    return {"access_token": make_token(key, "guest"), "token_type": "bearer", "name": "Campus Visitor", "role": "guest"}


@app.get("/users/me", tags=["Users"])
def me(identity: Identity, session: DbSession) -> dict:
    user = user_for_identity(identity, session)
    if user:
        return {**user.model_dump(), "sdu_id": user.email.split("@", 1)[0]}
    return {"name": "Campus Visitor", "role": "guest", "session": identity["sub"]}


@app.get("/users/me/preferences", tags=["Users"])
def get_preferences(identity: Identity, session: DbSession) -> dict:
    user = user_for_identity(identity, session)
    if not user:
        raise HTTPException(status_code=403, detail="Registered account required")
    preference = session.exec(select(Preference).where(Preference.user_id == user.id)).first()
    if preference is None:
        preference = Preference(user_id=user.id)
        session.add(preference)
        session.commit()
        session.refresh(preference)
    return {"accessible_routes": preference.accessible_routes}


@app.put("/users/me/preferences", tags=["Users"])
def update_preferences(body: PreferenceRequest, identity: Identity, session: DbSession) -> dict:
    user = user_for_identity(identity, session)
    if not user:
        raise HTTPException(status_code=403, detail="Registered account required")
    preference = session.exec(select(Preference).where(Preference.user_id == user.id)).first()
    if preference is None:
        preference = Preference(user_id=user.id)
        session.add(preference)
    preference.accessible_routes = body.accessible_routes
    session.commit()
    return {"accessible_routes": preference.accessible_routes}


@app.get("/locations", response_model=list[Location], tags=["Campus"])
def locations(session: DbSession, category: str | None = None) -> list[Location]:
    statement = select(Location)
    if category:
        statement = statement.where(Location.category == category)
    return list(session.exec(statement).all())


@app.get("/locations/{location_id}", response_model=Location, tags=["Campus"])
def location(location_id: int, session: DbSession) -> Location:
    item = session.get(Location, location_id)
    if not item:
        raise HTTPException(status_code=404, detail="Location not found")
    return item


@app.get("/search", response_model=list[Location], tags=["Campus"])
def search_locations(session: DbSession, q: str = Query(min_length=1), actor: str = "public") -> list[Location]:
    pattern = f"%{q.strip()}%"
    statement = select(Location).where(or_(Location.name.ilike(pattern), Location.category.ilike(pattern), Location.block.ilike(pattern), Location.aliases.ilike(pattern)))
    results = list(session.exec(statement).all())
    session.add(SearchLog(actor=actor, query=q))
    session.commit()
    return results


@app.get("/services", response_model=list[Location], tags=["Campus"])
def services(session: DbSession) -> list[Location]:
    return list(session.exec(select(Location).where(Location.category != "Classroom")).all())


@app.get("/announcements", response_model=list[Announcement], tags=["Campus"])
def list_announcements(session: DbSession) -> list[Announcement]:
    return list(session.exec(select(Announcement).order_by(Announcement.published_at.desc())).all())


@app.get("/routes", tags=["Navigation"])
def get_route(session: DbSession, destination: int, start: int = 1, accessible: bool = False) -> dict:
    target = session.get(Location, destination)
    if not target:
        raise HTTPException(status_code=404, detail="Destination not found")
    steps = ["Enter through the main Block C entrance", "Continue through the central atrium", f"Follow signs toward {target.block}", "Use the elevator" if accessible else "Use the nearest stairs or elevator", f"Arrive at {target.name}"]
    return {"start_location_id": start, "destination": target, "distance_m": 420, "duration_min": 7 if accessible else 6, "accessible": accessible, "steps": steps}


@app.post("/assistant/query", tags=["Assistant"])
def assistant(body: AssistantRequest, session: DbSession) -> dict:
    q = body.question.lower()
    mapping = {"park": 10, "print": 7, "eat": 3, "food": 3, "coffee": 3, "library": 2, "study": 2, "medical": 6, "doctor": 6, "toilet": 8, "restroom": 8, "317": 4, "next class": 4}
    matched_id = next((value for key, value in mapping.items() if key in q), None)
    if matched_id:
        item = session.get(Location, matched_id)
        return {"answer": f"I found {item.name} in {item.block}, {item.floor}.", "location": item, "needs_clarification": False}
    return {"answer": "Do you mean a classroom, office, food service, or another facility?", "location": None, "needs_clarification": True}


@app.get("/students/me/timetable", response_model=list[CampusClass], tags=["Schedules"])
def student_timetable(identity: Identity, session: DbSession) -> list[CampusClass]:
    user = user_for_identity(identity, session)
    if not user:
        raise HTTPException(status_code=403, detail="Registered account required")
    return list(session.exec(select(CampusClass).where(CampusClass.owner_email == user.email)).all())


@app.get("/students/me/next-class", response_model=CampusClass | None, tags=["Schedules"])
def next_class(identity: Identity, session: DbSession):
    user = user_for_identity(identity, session)
    if not user:
        raise HTTPException(status_code=403, detail="Registered account required")
    return session.exec(select(CampusClass).where(CampusClass.owner_email == user.email)).first()


@app.get("/teachers/me/schedule", response_model=list[CampusClass], tags=["Schedules"])
def teacher_schedule(identity: Identity, session: DbSession) -> list[CampusClass]:
    if identity["role"] not in {"teacher", "admin"}:
        raise HTTPException(status_code=403, detail="Teacher role required")
    user = user_for_identity(identity, session)
    if not user:
        raise HTTPException(status_code=403, detail="Registered account required")
    return list(session.exec(select(CampusClass).where(CampusClass.owner_email == user.email)).all())


@app.get("/users/me/favorites", response_model=list[Location], tags=["Users"])
def favorites(identity: Identity, session: DbSession) -> list[Location]:
    user = user_for_identity(identity, session)
    if not user:
        return []
    ids = [fav.location_id for fav in session.exec(select(Favorite).where(Favorite.user_id == user.id)).all()]
    return list(session.exec(select(Location).where(Location.id.in_(ids))).all()) if ids else []


@app.post("/users/me/favorites/{location_id}", status_code=201, tags=["Users"])
def add_favorite(location_id: int, identity: Identity, session: DbSession) -> dict:
    user = user_for_identity(identity, session)
    if not user:
        raise HTTPException(status_code=403, detail="Registered account required")
    existing = session.exec(select(Favorite).where(Favorite.user_id == user.id, Favorite.location_id == location_id)).first()
    if not existing:
        session.add(Favorite(user_id=user.id, location_id=location_id))
        session.commit()
    return {"saved": True, "location_id": location_id}


@app.delete("/users/me/favorites/{location_id}", tags=["Users"])
def remove_favorite(location_id: int, identity: Identity, session: DbSession) -> dict:
    user = user_for_identity(identity, session)
    if user:
        existing = session.exec(select(Favorite).where(Favorite.user_id == user.id, Favorite.location_id == location_id)).first()
        if existing:
            session.delete(existing)
            session.commit()
    return {"saved": False, "location_id": location_id}


@app.post("/reports", response_model=InaccuracyReport, status_code=201, tags=["Reports"])
def create_report(body: ReportRequest, identity: Identity, session: DbSession) -> InaccuracyReport:
    report = InaccuracyReport(author=identity["sub"], location_id=body.location_id, message=body.message)
    session.add(report)
    session.commit()
    session.refresh(report)
    return report


@app.get("/reports/me", response_model=list[InaccuracyReport], tags=["Reports"])
def my_reports(identity: Identity, session: DbSession) -> list[InaccuracyReport]:
    return list(session.exec(select(InaccuracyReport).where(InaccuracyReport.author == identity["sub"])).all())


@app.get("/admin/users", response_model=list[User], tags=["Administration"])
def admin_users(_: AdminIdentity, session: DbSession) -> list[User]:
    return list(session.exec(select(User)).all())


@app.put("/admin/users/{user_id}/roles", response_model=User, tags=["Administration"])
def set_role(user_id: int, body: RoleRequest, _: AdminIdentity, session: DbSession) -> User:
    if body.role not in {"student", "teacher", "admin"}:
        raise HTTPException(status_code=422, detail="Unsupported role")
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = body.role
    session.add(RoleOverride(email=user.email, role=body.role, reason="Assigned by administrator"))
    session.commit()
    session.refresh(user)
    return user


@app.post("/admin/locations", response_model=Location, status_code=201, tags=["Administration"])
def add_location(body: LocationRequest, _: AdminIdentity, session: DbSession) -> Location:
    item = Location(**body.model_dump())
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@app.put("/admin/locations/{location_id}", response_model=Location, tags=["Administration"])
def edit_location(location_id: int, body: LocationRequest, _: AdminIdentity, session: DbSession) -> Location:
    item = session.get(Location, location_id)
    if not item:
        raise HTTPException(status_code=404, detail="Location not found")
    for key, value in body.model_dump().items():
        setattr(item, key, value)
    session.commit()
    session.refresh(item)
    return item


@app.get("/admin/reports", response_model=list[InaccuracyReport], tags=["Administration"])
def admin_reports(_: AdminIdentity, session: DbSession) -> list[InaccuracyReport]:
    return list(session.exec(select(InaccuracyReport).order_by(InaccuracyReport.created_at.desc())).all())


@app.put("/admin/reports/{report_id}", response_model=InaccuracyReport, tags=["Administration"])
def update_report(report_id: int, body: StatusRequest, _: AdminIdentity, session: DbSession) -> InaccuracyReport:
    report = session.get(InaccuracyReport, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    report.status = body.status
    session.commit()
    session.refresh(report)
    return report


@app.get("/admin/analytics/popular-searches", tags=["Administration"])
def popular_searches(_: AdminIdentity, session: DbSession) -> list[dict]:
    logs = session.exec(select(SearchLog)).all()
    counts: dict[str, int] = {}
    for log in logs:
        counts[log.query.lower()] = counts.get(log.query.lower(), 0) + 1
    if not counts:
        counts = {"room 317": 86, "library": 71, "food court": 54, "printer": 38}
    return [{"query": query, "count": count} for query, count in sorted(counts.items(), key=lambda x: x[1], reverse=True)]
