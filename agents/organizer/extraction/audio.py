"""
agents/organizer/extraction/audio.py — extractor for form_id='audio'.

Podcast episodes, recorded lectures, audio interviews.
Tries to pull RSS/show-notes metadata and transcript if available.
"""
from __future__ import annotations
from typing import Optional
import httpx

from .base import BaseExtractor, EvidencePointer, ExtractionResult


class AudioExtractor(BaseExtractor):

    async def extract(self, url: str, access_mode: str,
                      raw: Optional[bytes] = None) -> ExtractionResult:
        if access_mode == "skip":
            return ExtractionResult(success=True, canonical_url=url)
        if access_mode == "link_out_only":
            return self._link_out_result(url)

        meta = await _fetch_audio_meta(url)

        if access_mode == "metadata_only":
            return ExtractionResult(
                success=True, canonical_url=url,
                title=meta.get("title"),
                creator_authors=meta.get("authors"),
                source_name=meta.get("show_name") or meta.get("publisher"),
                source_type="creator",
                description=meta.get("description"),
                metadata=meta,
            )

        # Transcript via show notes page (best effort)
        transcript = meta.get("transcript_text", "")
        pointers = []
        if transcript:
            chunk_size = 800
            for i in range(0, len(transcript), chunk_size):
                pointers.append(EvidencePointer(
                    pointer_type="transcript_segment",
                    pointer_value={"char_offset": i},
                    claim_text=transcript[i:i + chunk_size],
                ))

        return ExtractionResult(
            success=True, canonical_url=url,
            title=meta.get("title"),
            summary=meta.get("description", "")[:400],
            description=meta.get("description"),
            creator_authors=meta.get("authors"),
            source_name=meta.get("show_name") or meta.get("publisher"),
            source_type="creator",
            evidence_pointers=pointers,
            raw_text=transcript,
            metadata=meta,
        )


async def _fetch_audio_meta(url: str) -> dict:
    """Pull Open Graph / meta tags from the episode page."""
    try:
        async with httpx.AsyncClient(timeout=10, follow_redirects=True) as c:
            r = await c.get(url, headers={"User-Agent": "RumuoBot/0.1"})
            if r.status_code != 200:
                return {}
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(r.content, "html.parser")
        def og(p):
            return (soup.find("meta", property=p) or {}).get("content", "")
        def nm(n):
            return (soup.find("meta", attrs={"name": n}) or {}).get("content", "")
        return {
            "title":          og("og:title") or (soup.find("title") or {}).get_text(strip=True),
            "description":    og("og:description") or nm("description"),
            "show_name":      og("og:site_name"),
            "authors":        [nm("author")] if nm("author") else None,
            "published_date": nm("date") or og("article:published_time"),
        }
    except Exception:
        return {}
