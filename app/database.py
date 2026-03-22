from dotenv import load_dotenv

from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", f"postgresql://{os.getenv("POSTGRES_USER")}:{os.getenv("POSTGRES_PASSWORD")}@db:5432/pawnder_db")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Helper to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
