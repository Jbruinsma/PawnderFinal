from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import verify_password, create_access_token, get_current_user
from app.models.user import User
from app.crud.crud_user import create_user, get_user_by_email
from app.database import get_db
from app.schemas.user import UserCreate, UserResponse, UserLogin, Token, UserLocationUpdate, UserLocationResponse
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

router = APIRouter(
    prefix="/auth",
    tags=["1.0 Auth & Profile"]
)

@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    summary="Create a new user",
)
def register_user(
        user_in: UserCreate,
        session: Session = Depends(get_db)
):
    """
    DFD Action: Writes to D1: User Accounts.
    Task:
    - Accept schemas.UserCreate.
    - Hash the password.
    - Save to PostgreSQL.
    - Return schemas.UserResponse.
    """
    existing_user = get_user_by_email(
        session= session,
        email= user_in.email
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists.",
        )

    user: User = create_user(
        session= session,
        user_in= user_in
    )

    access_token = create_access_token(data={"sub": str(user.id)})
    token_response = {
        "access_token": access_token,
        "token_type": "bearer",
    }

    return {
        "token": token_response,
        "email": user.email,
        "role": user.role
    }


@router.post("/login", response_model=Token, summary="Authenticate and receive token")
def login_for_access_token(user_in: UserLogin, session: Session = Depends(get_db)):
    """
    DFD Action: Processes "Credentials & Auth Request".
    Task:
    - Verify email and password against D1.
    - Generate and return a JWT (JSON Web Token) for the "Session".
    """
    user = get_user_by_email(
        session= session,
        email= user_in.email
    )

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


@router.put(
    "/me/location",
    response_model=UserLocationResponse,
    summary="Update user's spatial context"
)
def update_user_location(
    location_in:UserLocationUpdate,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    point = Point(location_in.longitude, location_in.latitude)
    current_user.last_known_location = from_shape(point, srid=4326)

    session.add(current_user)
    session.commit()
    session.refresh(current_user)

    return {
        "message": "Location updated successfully.",
        "last_known_location": {
            "latitude": location_in.latitude,
            "longitude": location_in.longitude,
        },
    }