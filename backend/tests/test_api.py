import os

os.environ["DATABASE_URL"] = "sqlite:///./test_sdu_campus.db"

from fastapi.testclient import TestClient
from app.main import app, seed_database


seed_database()
client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_student_role_and_map_data():
    login = client.post("/auth/register-or-login", json={"email": "240103049@sdu.edu.kz"})
    assert login.status_code == 200
    assert login.json()["role"] == "student"
    locations = client.get("/locations")
    assert locations.status_code == 200
    assert any(item["name"] == "Room 317" for item in locations.json())


def test_admin_role_override():
    login = client.post("/auth/register-or-login", json={"email": "240000002@sdu.edu.kz"})
    assert login.status_code == 200
    assert login.json()["role"] == "admin"


def test_preferences_and_favorites_are_persisted():
    login = client.post("/auth/register-or-login", json={"email": "240103050@sdu.edu.kz"})
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    preference = client.put(
        "/users/me/preferences",
        json={"accessible_routes": True},
        headers=headers,
    )
    assert preference.status_code == 200
    assert client.get("/users/me/preferences", headers=headers).json()["accessible_routes"] is True

    saved = client.post("/users/me/favorites/2", headers=headers)
    assert saved.status_code == 201
    favorites = client.get("/users/me/favorites", headers=headers).json()
    assert any(item["id"] == 2 for item in favorites)
