import logging
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.database import engine
from . import models
from .api.v1 import auth, community, messages, search
from .core.config import settings

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
app.include_router(messages.router, prefix="/api/v1")
app.include_router(messages.messages_router, prefix="/api/v1")
app.include_router(search.router, prefix="/api/v1")

@app.get("/")
def read_root():
    return {
        "message": "Pawnder API is running!",
        "user": settings.postgres_user
    }