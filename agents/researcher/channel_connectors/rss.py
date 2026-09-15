"""
agents/researcher/channel_connectors/rss.py

RSS/Atom feed connector — pulls new entries from pre-configured feeds.
Seed feeds are in the medicine_nigeria.yaml approved source list.
"""
from __future__ import annotations
import httpx
from .base import BaseConnector, CandidateURL

class RSSConnector(BaseConnector):
    async def discover(self, query: str, limit: int = 20) -> list[CandidateURL]:
        """
        query here is expected to be an RSS feed URL (passed from the priority queue).
        Returns candidate URLs from the feed entries.
        """
        self._check_acquisition_gate()
        try:
            import feedparser
            async with httpx.AsyncClient(timeout=15) as c:
                r = await c.get(query)
            feed = feedparser.parse(r.text)
            candidates = []
            for entry in feed.entries[:limit]:
                candidates.append(CandidateURL(
                    url=entry.get("link", ""),
                    information_form="written",
                    source_type="publisher",
                    source_name=feed.feed.get("title", "Unknown"),
                    title=entry.get("title"),
                    discovery_path=f"rss:{query}",
                ))
            return [c for c in candidates if c.url]
        except Exception:
            return []
