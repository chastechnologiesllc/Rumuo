"""
agents/researcher/channel_connectors/web_crawl.py

General web crawl connector — discovers public pages via search or sitemap.
Uses DuckDuckGo HTML search (no API key required).
MUST NOT follow robots.txt-disallowed paths.
"""
from __future__ import annotations
import httpx
from .base import BaseConnector, CandidateURL

class WebCrawlConnector(BaseConnector):
    async def discover(self, query: str, limit: int = 20) -> list[CandidateURL]:
        self._check_acquisition_gate()
        search_url = f"https://html.duckduckgo.com/html/?q={query}+site:ng+medical"
        try:
            async with httpx.AsyncClient(timeout=15, follow_redirects=True,
                                         headers={"User-Agent": "RumuoBot/0.1"}) as c:
                r = await c.get(search_url)
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(r.content, "html.parser")
            links = soup.select("a.result__url")[:limit]
        except Exception:
            return []
        return [
            CandidateURL(
                url=f"https://{a.get_text(strip=True)}",
                information_form="written",
                source_type="publisher",
                source_name=a.get_text(strip=True).split("/")[0],
                discovery_path=f"web_crawl:duckduckgo:{query}",
            )
            for a in links
        ]
