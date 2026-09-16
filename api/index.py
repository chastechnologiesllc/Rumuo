"""
api/index.py — Vercel serverless entry point for the Rumuo experience API.

Mangum wraps the FastAPI ASGI app so Vercel's Python runtime can call it.
lifespan="off" because Vercel has no persistent process — db.py lazy-inits on
the first request instead (SERVERLESS=1 env var must be set in Vercel dashboard).
"""
from mangum import Mangum
from services.experience_api.main import app

handler = Mangum(app, lifespan="off")
