from geoalchemy2.shape import from_shape
from shapely.geometry import Point, Polygon

from app.core.security import get_password_hash
from app.database import SessionLocal
from app.models.community import Community
from app.models.post import Post, Tag
from app.models.user import User


TEST_PASSWORD = "pawnder123"
NYC_LAT = 40.7128
NYC_LON = -74.0060


def point(longitude: float, latitude: float):
    return from_shape(Point(longitude, latitude), srid=4326)


def polygon(coordinates: list[tuple[float, float]]):
    return from_shape(Polygon(coordinates), srid=4326)


def get_or_create_user(db, *, email: str, full_name: str, role: str, longitude: float, latitude: float) -> User:
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        user = User(
            role=role,
            email=email,
            full_name=full_name,
            password_hash=get_password_hash(TEST_PASSWORD),
        )
        db.add(user)
        db.flush()

    user.role = role
    user.full_name = full_name
    user.last_known_location = point(longitude, latitude)
    return user


def get_or_create_tag(db, *, category: str, name: str) -> Tag:
    tag = db.query(Tag).filter(Tag.category == category, Tag.name == name).first()
    if tag is None:
        tag = Tag(category=category, name=name)
        db.add(tag)
        db.flush()
    return tag


def get_or_create_post(
    db,
    *,
    author: User,
    title: str,
    description: str,
    post_type: str,
    longitude: float,
    latitude: float,
    status: str,
    tags: list[Tag],
) -> Post:
    post = db.query(Post).filter(Post.title == title, Post.author_id == author.id).first()
    if post is None:
        post = Post(
            author_id=author.id,
            title=title,
            description=description,
            post_type=post_type,
            status=status,
            location=point(longitude, latitude),
        )
        db.add(post)
        db.flush()

    post.description = description
    post.post_type = post_type
    post.status = status
    post.location = point(longitude, latitude)
    post.tags = tags
    return post


def get_or_create_community(db, *, name: str, description: str, boundary: list[tuple[float, float]]) -> Community:
    community = db.query(Community).filter(Community.name == name).first()
    if community is None:
        community = Community(name=name, description=description)
        db.add(community)
        db.flush()

    community.description = description
    community.geofence_boundary = polygon(boundary)
    return community


def seed() -> None:
    db = SessionLocal()
    try:
        explorer = get_or_create_user(
            db,
            email="geo.explorer@example.com",
            full_name="Geo Explorer",
            role="Community User",
            longitude=NYC_LON,
            latitude=NYC_LAT,
        )
        reporter = get_or_create_user(
            db,
            email="neighborhood.reporter@example.com",
            full_name="Neighborhood Reporter",
            role="Community User",
            longitude=-74.0048,
            latitude=40.7136,
        )
        shelter = get_or_create_user(
            db,
            email="rescue.partner@example.com",
            full_name="Rescue Partner",
            role="Shelter/Moderator",
            longitude=-74.0082,
            latitude=40.7119,
        )

        dog_tag = get_or_create_tag(db, category="Species", name="Dog")
        cat_tag = get_or_create_tag(db, category="Species", name="Cat")
        lost_tag = get_or_create_tag(db, category="Status", name="Lost")
        found_tag = get_or_create_tag(db, category="Status", name="Found")

        tribeca_watch = get_or_create_community(
            db,
            name="Tribeca Watch",
            description="Test neighborhood covering the seeded downtown posts.",
            boundary=[
                (-74.0080, 40.7115),
                (-74.0038, 40.7115),
                (-74.0038, 40.7148),
                (-74.0080, 40.7148),
                (-74.0080, 40.7115),
            ],
        )

        get_or_create_post(
            db,
            author=reporter,
            title="Golden retriever seen near Tribeca park",
            description="Friendly dog spotted near the benches around lunch time.",
            post_type="Sighting",
            longitude=-74.0057,
            latitude=40.7132,
            status="Active",
            tags=[dog_tag, found_tag],
        )
        get_or_create_post(
            db,
            author=shelter,
            title="Missing tabby cat with blue collar",
            description="Last seen near the corner deli two blocks east.",
            post_type="Lost Pet",
            longitude=-74.0049,
            latitude=40.7123,
            status="Active",
            tags=[cat_tag, lost_tag],
        )
        get_or_create_post(
            db,
            author=reporter,
            title="Small brown dog by Hudson walkway",
            description="Nervous dog running north along the waterfront path.",
            post_type="Sighting",
            longitude=-74.0074,
            latitude=40.7141,
            status="Active",
            tags=[dog_tag],
        )
        get_or_create_post(
            db,
            author=shelter,
            title="Old flyer from uptown",
            description="This post should stay out of the feed because it is too far away.",
            post_type="Lost Pet",
            longitude=-73.9680,
            latitude=40.7851,
            status="Active",
            tags=[dog_tag, lost_tag],
        )
        get_or_create_post(
            db,
            author=explorer,
            title="My own cat note",
            description="This post should not appear in my feed because it belongs to the current user.",
            post_type="Lost Pet",
            longitude=-74.0058,
            latitude=40.7127,
            status="Active",
            tags=[cat_tag],
        )

        db.commit()

        print("Seed complete.")
        print("Login user: geo.explorer@example.com")
        print(f"Password: {TEST_PASSWORD}")
        print(f"Neighborhood community id: {tribeca_watch.id}")
        print("Expected feed behavior:")
        print("- /api/v1/geo/feed returns nearby posts from other users")
        print("- tags=Dog returns the two nearby dog posts")
        print("- tags=Cat returns the nearby cat post")
        print("- /api/v1/geo/neighborhood/{community_id}/feed returns the downtown posts inside Tribeca Watch")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
