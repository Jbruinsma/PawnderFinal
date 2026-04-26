from contextlib import asynccontextmanager
import os
import logging

from dotenv import load_dotenv
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi.middleware.cors import CORSMiddleware

from .api.v1 import auth, geo, community, messages, search
from .database import engine, get_db
from . import models

load_dotenv()
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(_: FastAPI):
    try:
        models.Base.metadata.create_all(bind=engine)
    except Exception as exc:
        logger.warning("Database initialization skipped: %s", exc)
    yield

app = FastAPI(title="Pawnder API - Dev", lifespan=lifespan)


app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost:.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(community.router, prefix="/api/v1")
app.include_router(geo.router, prefix="/api/v1")
app.include_router(messages.router, prefix="/api/v1")
app.include_router(messages.messages_router, prefix="/api/v1")
app.include_router(search.router, prefix="/api/v1")

@app.get("/")
def read_root():
    return {
        "message": "Pawnder API is running!",
        "user": os.getenv("POSTGRES_USER")
    }

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    try:
        result = db.execute(text("SELECT postgis_full_version();"))
        version = result.fetchone()[0]

        table_check = db.execute(text("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public';"))
        tables = [row[0] for row in table_check.fetchall()]

        return {
            "status": "Connected to PostGIS",
            "version": version,
            "initialized_tables": tables
        }
    except Exception as e:
        return {"status": "Error", "details": str(e)}