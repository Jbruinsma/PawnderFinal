from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.user import User
from app.schemas.user import UserCreate


def get_user_by_email(session: Session, email: str) -> User | None:
    return session.query(User).filter(User.email == email).first()


def create_user(session: Session, user_in: UserCreate) -> User:
    db_user = User(
        role= user_in.role,
        email= user_in.email,
        full_name= user_in.full_name,
        password_hash= get_password_hash(user_in.password),
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user
