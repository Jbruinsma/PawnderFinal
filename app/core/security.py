import base64
import hashlib
import hmac
import json
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.database import get_db
from app.models.user import User

bearer_scheme = HTTPBearer()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Compares a plain text password against a stored hash.
    Used in: /api/v1/auth/login

    Task for Team:
    - Initialize a CryptContext (e.g., bcrypt).
    - Return the boolean result of the context verification.
    """
    try:
        algorithm, salt, stored_hash = hashed_password.split("$", 2)
    except ValueError:
        return False

    if algorithm != "pbkdf2_sha256":
        return False
    computed_hash = hashlib.pbkdf2_hmac(
        "sha256",
        plain_password.encode("utf-8"),
        salt.encode("utf-8"),
        100000,
    )
    encoded_hash = base64.b64encode(computed_hash).decode("utf-8")
    return hmac.compare_digest(encoded_hash, stored_hash)

def get_password_hash(password: str) -> str:
    """
    Hashes a plain text password before saving it to D1: User Accounts.
    Used in: /api/v1/auth/register

    Task for Team:
    - Use CryptContext to hash the incoming string.
    """
    salt = secrets.token_hex(16)
    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        100000,
    )
    encoded_hash = base64.b64encode(password_hash).decode("utf-8")
    return f"pbkdf2_sha256${salt}${encoded_hash}"


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Generates an access token for the user's session.
    """

    payload = data.copy()

    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    payload["exp"] = int(expire.timestamp())

    message = json.dumps(payload, sort_keys=True).encode("utf-8")
    signature = hmac.new(
        settings.secret_key.encode("utf-8"),
        message,
        hashlib.sha256,
    ).hexdigest()

    token_payload = {
        "payload": payload,
        "signature": signature,
    }

    token = base64.urlsafe_b64encode(
        json.dumps(token_payload).encode("utf-8")
    ).decode("utf-8")

    return token

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )

    try:
        decoded = base64.urlsafe_b64decode(token.encode("utf-8")).decode("utf-8")
        token_data = json.loads(decoded)

        payload = token_data["payload"]
        signature = token_data["signature"]

        expected_signature = hmac.new(
            settings.secret_key.encode("utf-8"),
            json.dumps(payload, sort_keys=True).encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

        if not hmac.compare_digest(signature, expected_signature):
            raise credentials_exception

        exp = payload.get("exp")
        if exp is None or datetime.now(timezone.utc).timestamp() > exp:
            raise credentials_exception

        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception

    except Exception:
        raise credentials_exception

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception

    return user