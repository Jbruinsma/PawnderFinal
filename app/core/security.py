from datetime import timedelta
from typing import Optional

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Compares a plain text password against a stored hash.
    Used in: /api/v1/auth/login

    Task for Team:
    - Initialize a CryptContext (e.g., bcrypt).
    - Return the boolean result of the context verification.
    """
    return False


def get_password_hash(password: str) -> str:
    """
    Hashes a plain text password before saving it to D1: User Accounts.
    Used in: /api/v1/auth/register

    Task for Team:
    - Use CryptContext to hash the incoming string.
    """
    return "dummy_hashed_string"


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Generates a JWT (JSON Web Token) for the user's session.

    Task for Team:
    - Copy the incoming data dict.
    - Set an expiration time.
    - Encode the token using settings.secret_key and settings.algorithm.
    """
    return "dummy.jwt.token"


def get_current_user(token: str):
    """
    FastAPI Dependency to protect specific routes (like creating a post).

    Task for Team:
    - Decode the JWT using python-jose.
    - Extract the user ID from the token payload.
    - Query the database to ensure the user still exists.
    - Return the User model (or raise an HTTPException if invalid).
    """
    return None