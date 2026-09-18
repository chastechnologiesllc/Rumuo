"""
agents/organizer/extraction/structured_interactive.py
Extractor for form_id='structured_interactive'.

Covers: online courses (MOOC), clinical decision tools, datasets, simulations,
drug formularies, Q&A platforms, interactive calculators.

Full extraction: fetch course outline / dataset manifest / tool description page.
Evidence pointers: one 'page' pointer per top-level section/module.
"""
from __future__ import annotations
from typing import Optional
import httpx

from .base import BaseExtractor, EvidencePointer, ExtractionResult


class StructuredInteractiveExtractor(BaseExtractor):

    async def extract(self, url: str, access_mode: str,
                      raw: Optional[bytes] = None) -> ExtractionResult:
        if access_mode == "skip":
            return ExtractionResult(success=True, canonical_url=url)
        if access_mode == "link_out_only":
            return self._link_out_result(url)

        html_bytes = raw or await _fetch(url)
        if html_bytes is None:
            return ExtractionResult(success=False, canonical_url=url,
                                    error="Could not fetch structured resource page")

        meta = _extract_meta(html_bytes, url)

        if access_mode == "metadata_only":
            return ExtractionResult(
                success=True, canonical_url=url,
                title=meta.get("title"),
                description=meta.get("description"),
                source_name=meta.get("site_name"),
                source_type="platform",
                metadata=meta,
            )

        # Full: extract section/module headings as 'page' evidence pointers
        sections = _extract_sections(html_bytes)
        pointers = [
            EvidencePointer(
                pointer_type="page",
                pointer_value={"section_index": i, "heading": s["heading"]},
                claim_text=s["text"][:600],
            )
            for i, s in enumerate(sections)
        ]

        return ExtractionResult(
            success=True, canonical_url=url,
            title=meta.get("title"),
            summary=meta.get("description") or (sections[0]["text"][:300] if sections else None),
            description=meta.get("description"),
            source_name=meta.get("site_name"),
            source_type="platform",
            evidence_pointers=pointers,
            raw_text="\n".join(s["text"] for s in sections),
            metadata=meta,
        )


async def _fetch(url: str) -> Optional[bytes]:
    try:
        async with httpx.AsyncClient(timeout=15, follow_redirects=True,
                                     headers={"User-Agent": "RumuoBot/0.1"}) as c:
            r = await c.get(url)
            return r.content if r.status_code == 200 else None
    except Exception:
        return None


def _extract_meta(html: bytes, url: str) -> dict:
    try:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html, "html.parser")
        def og(p):
            return (soup.find("meta", property=p) or {}).get("content", "")
        def nm(n):
            return (soup.find("meta", attrs={"name": n}) or {}).get("content", "")
        return {
            "title":       og("og:title") or (soup.find("title") or {}).get_text(strip=True),
            "description": og("og:description") or nm("description"),
            "site_name":   og("og:site_name"),
        }
    except Exception:
        return {}


def _extract_sections(html: bytes) -> list[dict]:
    """Extract heading+body pairs from the page as structured sections."""
    try:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html, "html.parser")
        sections = []
        for tag in soup.find_all(["h2", "h3", "h4"]):
            heading = tag.get_text(strip=True)
            body_parts = []
            for sib in tag.next_siblings:
                if sib.name in ("h2", "h3", "h4"):
                    break
                if hasattr(sib, "get_text"):
                    t = sib.get_text(strip=True)
                    if t:
                        body_parts.append(t)
            sections.append({"heading": heading, "text": heading + " " + " ".join(body_parts)})
        return sections
    except Exception:
        return []
