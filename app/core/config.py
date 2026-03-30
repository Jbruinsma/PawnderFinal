from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    postgres_user: str
    postgres_password: str
    postgres_db: str
    database_url: str

    # Future Auth configuration (Sia/Devin will need these later)
    # secret_key: str = "a_very_secret_key_for_development"
    secret_key: str = "a_very_secret_key_for_development"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # I WILL ADD THESE AND CONNECT THEM LATER

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

# Instantiate the settings so they can be imported anywhere in the app
settings = Settings()