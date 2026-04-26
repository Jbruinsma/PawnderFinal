from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    postgres_user: str
    postgres_password: str
    postgres_db: str
    database_url: str

    # Future Auth configuration (Sia/Devin will need these later)
    # secret_key: str = "a_very_secret_key_for_development"
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # I WILL ADD THESE AND CONNECT THEM LATER

    # OCI Object Storage (image uploads via pre-authenticated requests).
    # All optional so the app still boots in environments without OCI
    # credentials; the upload endpoint will return 503 if any are missing.
    oci_tenancy_ocid: str | None = None
    oci_user_ocid: str | None = None
    oci_fingerprint: str | None = None
    oci_key_file: str | None = None  # filesystem path to the PEM private key
    oci_region: str | None = None
    oci_namespace: str | None = None
    oci_bucket: str | None = None
    oci_par_lifetime_minutes: int = 10

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

# Instantiate the settings so they can be imported anywhere in the app
settings = Settings()