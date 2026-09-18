"""
api/review.py — Vercel Python entry point for the Rumuo Review Console.
Served at /review/* via vercel.json routes.
Protected by X-Reviewer-Token header.
"""
from services.trust.review_console.main import app

__all__ = ["app"]
