"""
api/index.py — Vercel Python entry point for the Rumuo Experience API.

Vercel's Python runtime serves FastAPI apps directly.
SERVERLESS=1 must be set in Vercel Project → Settings → Environment Variables.
"""
from services.experience_api.main import app

__all__ = ["app"]
