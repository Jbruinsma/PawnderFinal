from fastapi import APIRouter

router = APIRouter(
    prefix="/auth",
    tags=["1.0 Auth & Profile"]
)

@router.post("/register", summary="Create a new user")
def register_user():
    """
    DFD Action: Writes to D1: User Accounts.
    Task:
    - Accept schemas.UserCreate.
    - Hash the password.
    - Save to PostgreSQL.
    - Return schemas.UserResponse.
    """
    return {"message": "Endpoint not implemented yet."}


@router.post("/login", summary="Authenticate and receive token")
def login_for_access_token():
    """
    DFD Action: Processes "Credentials & Auth Request".
    Task:
    - Verify email and password against D1.
    - Generate and return a JWT (JSON Web Token) for the "Session".
    """
    return {"message": "Endpoint not implemented yet."}


@router.get("/me", summary="Get current user profile")
def read_current_user():
    """
    DFD Action: Provides "Session/Profile" context.
    Task:
    - Decode the JWT token.
    - Fetch user details from D1.
    - Return the user profile (to be used by Matthew's UI).
    """
    return {"message": "Endpoint not implemented yet."}


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