from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import verify_password, create_access_token, get_current_user
from app.models.user import User
from app.crud.crud_user import create_user, get_user_by_email
from app.database import get_db
from app.schemas.user import UserCreate, UserResponse, UserLogin, Token
router = APIRouter(
    prefix="/auth",
    tags=["1.0 Auth & Profile"]
)

@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new user",
)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    DFD Action: Writes to D1: User Accounts.
    Task:
    - Accept schemas.UserCreate.
    - Hash the password.
    - Save to PostgreSQL.
    - Return schemas.UserResponse.
    """
    existing_user = get_user_by_email(db, user_in.email)
    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists.",
        )

    return create_user(db, user_in)


@router.post("/login", response_model=Token, summary="Authenticate and receive token")
def login_for_access_token(user_in: UserLogin, db: Session = Depends(get_db)):
    """
    DFD Action: Processes "Credentials & Auth Request".
    Task:
    - Verify email and password against D1.
    - Generate and return a JWT (JSON Web Token) for the "Session".
    """
    user = get_user_by_email(db, user_in.email)

    if user is None or not verify_password(user_in.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    access_token = create_access_token(data={"sub": str(user.id)})
    return {
        "access_token" : access_token,
        "token_type" : "bearer",
    }


@router.get("/me", response_model=UserResponse, summary="Get current user profile")
def read_current_user(current_user: User = Depends(get_current_user)):
    """
    DFD Action: Provides "Session/Profile" context.
    Task:
    - Decode the JWT token.
    - Fetch user details from D1.
    - Return the user profile (to be used by Matthew's UI).
    """
    return current_user


@router.put("/me/location", summary="Update user's spatial context")
def update_user_location():
    """
    DFD Action: Updates "User Context & Current Location".
    Task:
    - Accept GPS coordinates from Matthew's Flutter app.
    - Convert to a PostGIS Point.
    - Save to the `last_known_location` column in D1.
    """
    return {"message": "Endpoint not implemented yet."}
