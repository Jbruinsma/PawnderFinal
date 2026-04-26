import uuid
from datetime import datetime, timedelta, timezone
from typing import Literal, Optional

import oci
from fastapi import APIRouter, Depends, HTTPException, status
from oci.object_storage.models import CreatePreauthenticatedRequestDetails
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import verify_password, create_access_token, get_current_user
from app.models.user import User
from app.crud.crud_user import create_user, get_user_by_email
from app.database import get_db
from app.schemas.user import UserCreate, UserResponse, UserLogin, Token, UserLocationUpdate, UserLocationResponse, \
    UserRegistrationResponseModel
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

router = APIRouter(
    prefix="/auth",
    tags=["1.0 Auth & Profile"]
)

@router.post(
    path= "/register",
    status_code= status.HTTP_201_CREATED,
    summary= "Create a new user",
    response_model= UserRegistrationResponseModel
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
    token_response = Token(access_token= access_token)

    return UserRegistrationResponseModel(
        token= token_response,
        email= user.email,
        role= user.role
    )


@router.post(
    path= "/login",
    summary= "Authenticate and receive token",
    response_model= Token
)
def login_for_access_token(
        user_in: UserLogin,
        session: Session = Depends(get_db)
):
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
    return Token(
        access_token= access_token
    )


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


# ---------------------------------------------------------------------------
# 3.0 Media Uploads
#
# Mints short-lived OCI Object Storage Pre-Authenticated Requests (PARs) so
# the Flutter client can PUT image bytes directly to the bucket. Bytes never
# pass through this service, which keeps the endpoint cheap and simple. The
# canonical public URL is returned alongside the upload URL and is what the
# client should embed in the create-post / create-community request.
# ---------------------------------------------------------------------------

ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
}

EXTENSION_FOR_TYPE = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/heic": "heic",
}


class UploadSignRequest(BaseModel):
    content_type: str = Field(
        ...,
        description="MIME type of the file the client intends to upload, e.g. 'image/jpeg'.",
    )
    purpose: Literal["post", "community"] = Field(
        ...,
        description="What the image is for. Determines the object key prefix in the bucket.",
    )


class UploadSignResponse(BaseModel):
    upload_url: str = Field(
        ...,
        description="Short-lived URL the client PUTs the raw bytes to.",
    )
    public_url: str = Field(
        ...,
        description="Canonical public URL the client should send back in the create request.",
    )
    object_key: str = Field(
        ...,
        description="The object key inside the bucket. Useful for debugging or deletion.",
    )


# Process-wide singleton, lazily built on first request so the app can boot
# without OCI credentials present in the environment.
_object_storage_client: Optional[oci.object_storage.ObjectStorageClient] = None


def _get_object_storage_client() -> oci.object_storage.ObjectStorageClient:
    """Build (once) and return the OCI Object Storage client.

    Raises a 503 HTTPException if the required env vars are not configured,
    so a misconfigured deployment surfaces a clear error to the client
    instead of a generic 500.
    """
    global _object_storage_client
    if _object_storage_client is not None:
        return _object_storage_client

    required = {
        "OCI_TENANCY_OCID": settings.oci_tenancy_ocid,
        "OCI_USER_OCID": settings.oci_user_ocid,
        "OCI_FINGERPRINT": settings.oci_fingerprint,
        "OCI_KEY_FILE": settings.oci_key_file,
        "OCI_REGION": settings.oci_region,
        "OCI_NAMESPACE": settings.oci_namespace,
        "OCI_BUCKET": settings.oci_bucket,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Image uploads are not configured on this server. Missing "
                "environment variables: " + ", ".join(missing)
            ),
        )

    oci_config = {
        "tenancy": settings.oci_tenancy_ocid,
        "user": settings.oci_user_ocid,
        "fingerprint": settings.oci_fingerprint,
        "key_file": settings.oci_key_file,
        "region": settings.oci_region,
    }
    oci.config.validate_config(oci_config)
    _object_storage_client = oci.object_storage.ObjectStorageClient(oci_config)
    return _object_storage_client


@router.post(
    path="/uploads/sign",
    status_code=status.HTTP_201_CREATED,
    summary="Mint a short-lived pre-authenticated upload URL for an image",
    response_model=UploadSignResponse,
    tags=["3.0 Media Uploads"],
)
def sign_image_upload(
    payload: UploadSignRequest,
    current_user: User = Depends(get_current_user),
):
    """
    DFD Action: Issues a write Pre-Authenticated Request (PAR) against the
    Pawnder OCI Object Storage bucket so the client can PUT image bytes
    directly without proxying through this service.

    Task:
    - Require an authenticated user.
    - Validate that content_type is an allowed image MIME type.
    - Generate a UUID-based object key namespaced by purpose
      (e.g. 'posts/<uuid>.jpg' or 'communities/<uuid>.png').
    - Create an ObjectWrite PAR via the OCI SDK with a short expiration.
    - Return the full upload URL plus the canonical public URL the client
      should embed in the create-post / create-community request.
    """
    content_type = payload.content_type.lower()
    if content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Unsupported content type '{payload.content_type}'. "
                f"Allowed: {sorted(ALLOWED_IMAGE_TYPES)}"
            ),
        )

    client = _get_object_storage_client()

    namespace = settings.oci_namespace
    bucket = settings.oci_bucket
    region = settings.oci_region

    extension = EXTENSION_FOR_TYPE[content_type]
    object_key = f"{payload.purpose}s/{uuid.uuid4()}.{extension}"

    par_details = CreatePreauthenticatedRequestDetails(
        name=f"upload-{object_key}",
        object_name=object_key,
        access_type=CreatePreauthenticatedRequestDetails.ACCESS_TYPE_OBJECT_WRITE,
        time_expires=datetime.now(timezone.utc)
        + timedelta(minutes=settings.oci_par_lifetime_minutes),
    )

    try:
        par_response = client.create_preauthenticated_request(
            namespace_name=namespace,
            bucket_name=bucket,
            create_preauthenticated_request_details=par_details,
        )
    except oci.exceptions.ServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"OCI rejected the upload request: {exc.message}",
        ) from exc

    base = f"https://objectstorage.{region}.oraclecloud.com"
    upload_url = f"{base}{par_response.data.access_uri}"
    public_url = f"{base}/n/{namespace}/b/{bucket}/o/{object_key}"

    return UploadSignResponse(
        upload_url=upload_url,
        public_url=public_url,
        object_key=object_key,
    )