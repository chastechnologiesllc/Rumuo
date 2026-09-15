"""
agents/researcher/channel_connectors/youtube_api.py

YouTube Data API v3 connector — finds public medical education videos.
Requires YOUTUBE_API_KEY in environment.
MUST NOT acquire private/unlisted content.
"""
from __future__ import annotations
from typing import Optional
import httpx
import os
from .base import BaseConnector, CandidateURL

_BASE = "https://www.googleapis.com/youtube/v3"

class YouTubeConnector(BaseConnector):
    async def discover(self, query: str, limit: int = 20) -> list[CandidateURL]:
        self._check_acquisition_gate()
        api_key = os.environ.get("YOUTUBE_API_KEY", "")
        if not api_key:
            return []
        params = {
            "part": "snippet", "q": query, "type": "video",
            "maxResults": min(limit, 50), "key": api_key,
            "relevanceLanguage": "en", "regionCode": "NG",
            "videoEmbeddable": "true", "videoSyndicated": "true",
        }
        try:
            async with httpx.AsyncClient(timeout=10) as c:
                r = await c.get(f"{_BASE}/search", params=params)
                items = r.json().get("items", [])
        except Exception:
            return []
        results = []
        for item in items:
            vid_id = item.get("id", {}).get("videoId")
            if not vid_id:
                continue
            snippet = item.get("snippet", {})
            form = "shorts" if "short" in snippet.get("title","").lower() else "video"
            results.append(CandidateURL(
                url=f"https://www.youtube.com/watch?v={vid_id}",
                information_form=form,
                source_type="platform",
                source_name="YouTube",
                title=snippet.get("title"),
                discovery_path=f"youtube_api:search:{query}",
            ))
        return results
