from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.api.v1 import geo
from app.core.security import get_current_user
from app.core.database import get_db
from app.main import app


@pytest.fixture
def client():
    app.dependency_overrides.clear()
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def override_db():
    yield object()


def test_geo_feed_requires_saved_location(client):
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(last_known_location=None)

    response = client.get("/api/v1/geo/feed")

    assert response.status_code == 400
    assert response.json() == {
        "detail": "Current user location is required before requesting the geo feed."
    }


def test_geo_feed_returns_crud_results(client, monkeypatch):
    expected_posts = [
        {
            "id": "8a6e8c2e-dfb0-46f6-bf22-a816fef4a955",
            "author_id": "d24f9b7a-b35a-4d0e-a9a6-e4fef4fb604c",
            "post_type": "Sighting",
            "title": "Dog near the park",
            "description": "Friendly dog spotted near the entrance.",
            "image_url": None,
            "status": "Active",
            "created_at": "2026-04-07T19:30:00Z",
            "location": {"latitude": 40.7132, "longitude": -74.0057},
            "tags": ["Dog", "Found"],
        }
    ]
    captured = {}

    def fake_get_geo_feed(db, *, user, radius_km, tags):
        captured["db"] = db
        captured["user"] = user
        captured["radius_km"] = radius_km
        captured["tags"] = tags
        return expected_posts

    monkeypatch.setattr(geo, "get_geo_feed", fake_get_geo_feed)
    current_user = SimpleNamespace(id="user-1", last_known_location="POINT")
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: current_user

    response = client.get("/api/v1/geo/feed?radius_km=12&tags=Dog&tags=Found")

    assert response.status_code == 200
    assert response.json() == expected_posts
    assert captured["user"] is current_user
    assert captured["radius_km"] == 12
    assert captured["tags"] == ["Dog", "Found"]


def test_geo_search_delegates_to_crud(client, monkeypatch):
    expected_posts = [
        {
            "id": "5b887a36-08fa-4f3d-a89a-674fe2f8bbde",
            "author_id": "c0d9b870-91ef-4f7a-9c8b-9cd26dbf3b6f",
            "post_type": "Lost Pet",
            "title": "Missing tabby cat",
            "description": "Seen near the deli last night.",
            "image_url": None,
            "status": "Active",
            "created_at": "2026-04-07T19:35:00Z",
            "location": {"latitude": 40.7123, "longitude": -74.0049},
            "tags": ["Cat", "Lost"],
        }
    ]
    captured = {}

    def fake_search_posts(db, *, lat, lon, radius_km, tags):
        captured["db"] = db
        captured["lat"] = lat
        captured["lon"] = lon
        captured["radius_km"] = radius_km
        captured["tags"] = tags
        return expected_posts

    monkeypatch.setattr(geo, "search_posts_by_radius_crud", fake_search_posts)
    app.dependency_overrides[get_db] = override_db

    response = client.get(
        "/api/v1/geo/search?lat=40.7128&lon=-74.0060&radius_km=5&tags=Cat"
    )

    assert response.status_code == 200
    assert response.json() == expected_posts
    assert captured["lat"] == 40.7128
    assert captured["lon"] == -74.006
    assert captured["radius_km"] == 5
    assert captured["tags"] == ["Cat"]


def test_geo_feed_requires_authentication(client):
    app.dependency_overrides[get_db] = override_db

    response = client.get("/api/v1/geo/feed")

    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}


def test_neighborhood_feed_returns_crud_results(client, monkeypatch):
    community_id = "d7df0d51-f0ee-440f-b6f8-0da0230185d0"
    expected_posts = [
        {
            "id": "51765087-db41-41cf-a1fa-c68ca5a1b95c",
            "author_id": "d24f9b7a-b35a-4d0e-a9a6-e4fef4fb604c",
            "post_type": "Sighting",
            "title": "Dog inside the neighborhood",
            "description": "Seen near the center of the community.",
            "image_url": None,
            "status": "Active",
            "created_at": "2026-04-07T20:00:00Z",
            "location": {"latitude": 40.7130, "longitude": -74.0059},
            "tags": ["Dog"],
        }
    ]
    captured = {}

    def fake_get_neighborhood_feed(db, *, community_id):
        captured["db"] = db
        captured["community_id"] = community_id
        return expected_posts

    monkeypatch.setattr(geo, "get_neighborhood_feed_crud", fake_get_neighborhood_feed)
    app.dependency_overrides[get_db] = override_db

    response = client.get(f"/api/v1/geo/neighborhood/{community_id}/feed")

    assert response.status_code == 200
    assert response.json() == expected_posts
    assert captured["community_id"] == community_id


def test_neighborhood_feed_returns_404_for_missing_community(client, monkeypatch):
    monkeypatch.setattr(geo, "get_neighborhood_feed_crud", lambda db, *, community_id: None)
    app.dependency_overrides[get_db] = override_db
    community_id = "d7df0d51-f0ee-440f-b6f8-0da0230185d0"

    response = client.get(f"/api/v1/geo/neighborhood/{community_id}/feed")

    assert response.status_code == 404
    assert response.json() == {
        "detail": f"Community {community_id} was not found."
    }


def test_neighborhood_feed_returns_400_for_missing_geofence(client, monkeypatch):
    def fake_get_neighborhood_feed(db, *, community_id):
        raise ValueError("Community geofence boundary is not configured.")

    monkeypatch.setattr(geo, "get_neighborhood_feed_crud", fake_get_neighborhood_feed)
    app.dependency_overrides[get_db] = override_db
    community_id = "d7df0d51-f0ee-440f-b6f8-0da0230185d0"

    response = client.get(f"/api/v1/geo/neighborhood/{community_id}/feed")

    assert response.status_code == 400
    assert response.json() == {
        "detail": "Community geofence boundary is not configured."
    }
