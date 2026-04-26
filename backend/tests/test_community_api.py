from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.api.v1 import community
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


def test_get_neighborhoods_returns_crud_results(client, monkeypatch):
    expected_communities = [
        {
            "id": "8963e610-de8a-4faf-a21c-dab4f2434c1f",
            "name": "Tribeca Watch",
            "description": "Test neighborhood covering the seeded downtown posts.",
        }
    ]
    monkeypatch.setattr(community, "list_communities", lambda db: expected_communities)
    app.dependency_overrides[get_db] = override_db

    response = client.get("/api/v1/community/neighborhoods")

    assert response.status_code == 200
    assert response.json() == expected_communities


def test_join_neighborhood_returns_joined_response(client, monkeypatch):
    community_id = "8963e610-de8a-4faf-a21c-dab4f2434c1f"
    expected_community = {
        "id": community_id,
        "name": "Tribeca Watch",
        "description": "Test neighborhood covering the seeded downtown posts.",
    }
    current_user = SimpleNamespace(id="user-1")

    def fake_join_community(db, *, user, community_id):
        assert user is current_user
        return expected_community, True

    monkeypatch.setattr(community, "join_community", fake_join_community)
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: current_user

    response = client.post(f"/api/v1/community/neighborhoods/{community_id}/join")

    assert response.status_code == 200
    assert response.json() == {
        "message": "Joined neighborhood successfully.",
        "community": expected_community,
    }


def test_join_neighborhood_returns_404_for_missing_community(client, monkeypatch):
    community_id = "8963e610-de8a-4faf-a21c-dab4f2434c1f"

    monkeypatch.setattr(
        community,
        "join_community",
        lambda db, *, user, community_id: (None, False),
    )
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id="user-1")

    response = client.post(f"/api/v1/community/neighborhoods/{community_id}/join")

    assert response.status_code == 404
    assert response.json() == {
        "detail": f"Community {community_id} was not found."
    }


def test_create_post_returns_crud_response(client, monkeypatch):
    expected_post = {
        "id": "dc386df6-fc56-4727-b087-18d2830f2c77",
        "author_id": "fd08d75d-e00a-4730-9169-b984073d50b0",
        "post_type": "Sighting",
        "title": "Dog near the corner store",
        "description": "Brown dog seen near the store around noon.",
        "image_url": None,
        "status": "Active",
        "created_at": "2026-04-21T03:40:33.178298Z",
        "location": {"latitude": 40.719, "longitude": -74.01},
        "tags": [],
    }
    current_user = SimpleNamespace(id="user-1")

    def fake_create_post(db, *, user, post_in):
        assert user is current_user
        assert post_in.title == "Dog near the corner store"
        return expected_post

    monkeypatch.setattr(community, "create_post_crud", fake_create_post)
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: current_user

    response = client.post(
        "/api/v1/community/posts",
        json={
            "post_type": "Sighting",
            "title": "Dog near the corner store",
            "description": "Brown dog seen near the store around noon.",
            "image_url": None,
            "location": {"latitude": 40.719, "longitude": -74.01},
            "tag_ids": [],
        },
    )

    assert response.status_code == 200
    assert response.json() == expected_post



def test_get_post_returns_crud_response(client, monkeypatch):
    post_id = "dc386df6-fc56-4727-b087-18d2830f2c77"
    expected_post = {
        "id": post_id,
        "author_id": "fd08d75d-e00a-4730-9169-b984073d50b0",
        "post_type": "Sighting",
        "title": "Dog near the corner store",
        "description": "Brown dog seen near the store around noon.",
        "image_url": None,
        "status": "Active",
        "created_at": "2026-04-21T03:40:33.178298Z",
        "location": {"latitude": 40.719, "longitude": -74.01},
        "tags": [],
    }

    monkeypatch.setattr(
        community,
        "get_post_by_id",
        lambda db, *, post_id: expected_post,
    )
    app.dependency_overrides[get_db] = override_db

    response = client.get(f"/api/v1/community/posts/{post_id}")

    assert response.status_code == 200
    assert response.json() == expected_post



def test_get_post_returns_404_for_missing_post(client, monkeypatch):
    post_id = "dc386df6-fc56-4727-b087-18d2830f2c77"

    monkeypatch.setattr(community, "get_post_by_id", lambda db, *, post_id: None)
    app.dependency_overrides[get_db] = override_db

    response = client.get(f"/api/v1/community/posts/{post_id}")

    assert response.status_code == 404
    assert response.json() == {
        "detail": f"Post {post_id} was not found."
    }



def test_get_tags_returns_crud_results(client, monkeypatch):
    expected_tags = [
        {
            "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "category": "Species",
            "name": "Dog",
        }
    ]

    monkeypatch.setattr(community, "list_tags", lambda db: expected_tags)
    app.dependency_overrides[get_db] = override_db

    response = client.get("/api/v1/community/tags")

    assert response.status_code == 200
    assert response.json() == expected_tags



def test_bookmark_post_returns_success_response(client, monkeypatch):
    post_id = "dc386df6-fc56-4727-b087-18d2830f2c77"
    current_user = SimpleNamespace(id="user-1")

    monkeypatch.setattr(
        community,
        "bookmark_post_crud",
        lambda db, *, user, post_id: SimpleNamespace(id=post_id),
    )
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: current_user

    response = client.post(f"/api/v1/community/posts/{post_id}/bookmark")

    assert response.status_code == 200
    assert response.json() == {
        "message": "Post bookmarked successfully.",
        "post_id": post_id,
    }



def test_bookmark_post_returns_404_for_missing_post(client, monkeypatch):
    post_id = "dc386df6-fc56-4727-b087-18d2830f2c77"

    monkeypatch.setattr(
        community,
        "bookmark_post_crud",
        lambda db, *, user, post_id: None,
    )
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id="user-1")

    response = client.post(f"/api/v1/community/posts/{post_id}/bookmark")

    assert response.status_code == 404
    assert response.json() == {
        "detail": f"Post {post_id} was not found."
    }



def test_get_bookmarks_returns_crud_results(client, monkeypatch):
    expected_posts = [
        {
            "id": "dc386df6-fc56-4727-b087-18d2830f2c77",
            "author_id": "fd08d75d-e00a-4730-9169-b984073d50b0",
            "post_type": "Sighting",
            "title": "Dog near the corner store",
            "description": "Brown dog seen near the store around noon.",
            "image_url": None,
            "status": "Active",
            "created_at": "2026-04-21T03:40:33.178298Z",
            "location": {"latitude": 40.719, "longitude": -74.01},
            "tags": [],
        }
    ]
    current_user = SimpleNamespace(id="user-1")

    def fake_list_bookmarked_posts(db, *, user):
        assert user is current_user
        return expected_posts

    monkeypatch.setattr(community, "list_bookmarked_posts", fake_list_bookmarked_posts)
    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = lambda: current_user

    response = client.get("/api/v1/community/bookmarks")

    assert response.status_code == 200
    assert response.json() == expected_posts



def test_bookmark_routes_require_authentication(client):
    app.dependency_overrides[get_db] = override_db

    response = client.get("/api/v1/community/bookmarks")

    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}
