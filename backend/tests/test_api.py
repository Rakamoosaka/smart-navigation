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
    login = client.post(
        "/auth/login",
        json={"sdu_id": "240103049", "password": "Campus123!"},
    )
    assert login.status_code == 200
    assert login.json()["role"] == "student"
    locations = client.get("/locations")
    assert locations.status_code == 200
    assert any(item["name"] == "Room 317" for item in locations.json())


def test_admin_role_override():
    login = client.post(
        "/auth/login",
        json={"sdu_id": "240000002", "password": "Campus123!"},
    )
    assert login.status_code == 200
    assert login.json()["role"] == "admin"


def test_preferences_and_favorites_are_persisted():
    login = client.post(
        "/auth/login",
        json={"sdu_id": "240103050", "password": "Campus123!"},
    )
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


def test_registration_requires_password_and_assigns_student_role():
    response = client.post(
        "/auth/register",
        json={
            "sdu_id": "250999991",
            "full_name": "New Student",
            "password": "StrongPass1!",
        },
    )
    if response.status_code == 409:
        response = client.post(
            "/auth/login",
            json={"sdu_id": "250999991", "password": "StrongPass1!"},
        )
    assert response.status_code in {200, 201}
    assert response.json()["role"] == "student"


def test_wrong_password_is_rejected():
    response = client.post(
        "/auth/login",
        json={"sdu_id": "240103049", "password": "definitely-wrong"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Incorrect ID or password"
