"""
agents/researcher/channel_connectors/openalex.py

OpenAlex API connector — discovers open-access research papers.
Uses the public API (no key required for polite use; set OPENALEX_EMAIL).
MUST NOT fetch paywalled full-text — metadata + open-access links only.
"""
from __future__ import annotations
import httpx
import os
from .base import BaseConnector, CandidateURL

_BASE = "https://api.openalex.org/works"

class OpenAlexConnector(BaseConnector):
    async def discover(self, query: str, limit: int = 20) -> list[CandidateURL]:
        self._check_acquisition_gate()
        email = os.environ.get("OPENALEX_EMAIL", "bot@rumuo.com")
        params = {
            "search": query,
            "filter": "is_oa:true,institutions.country_code:NG",
            "per-page": min(limit, 50),
            "mailto": email,
        }
        try:
            async with httpx.AsyncClient(timeout=15) as c:
                r = await c.get(_BASE, params=params)
            results = r.json().get("results", [])
        except Exception:
            return []
        candidates = []
        for w in results:
            url = (w.get("open_access") or {}).get("oa_url") or w.get("doi")
            if not url:
                continue
            candidates.append(CandidateURL(
                url=url,
                information_form="written",
                source_type="publisher",
                source_name=(w.get("primary_location") or {}).get("source", {}).get("display_name", "Unknown"),
                title=w.get("title"),
                discovery_path=f"openalex_api:{query}",
            ))
        return candidates
