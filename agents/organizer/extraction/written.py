"""
agents/organizer/extraction/written.py — extractor for form_id='written'.

Handles articles, blog posts, PDFs, research papers, books.
Uses trafilatura for clean text extraction; falls back to BeautifulSoup.
Produces article_section evidence pointers.
"""
from __future__ import annotations
from typing import Optional

import httpx

from .base import BaseExtractor, EvidencePointer, ExtractionResult

_SECTION_CHAR_LIMIT = 800   # max chars per article_section evidence pointer


class WrittenExtractor(BaseExtractor):

    async def extract(
        self,
        url: str,
        access_mode: str,
        raw: Optional[bytes] = None,
    ) -> ExtractionResult:
        if access_mode == "skip":
            return ExtractionResult(success=True, canonical_url=url)
        if access_mode == "link_out_only":
            return self._link_out_result(url)

        # Fetch raw HTML/PDF
        html_bytes = raw
        if html_bytes is None and access_mode in ("full", "metadata_only"):
            html_bytes = await _fetch(url)

        if html_bytes is None:
            return ExtractionResult(success=False, canonical_url=url,
                                    error="Fetch failed — no content retrieved")

        # Meta always extracted from Open Graph / head tags
        meta = _extract_meta(html_bytes, url)

        if access_mode == "metadata_only":
            return ExtractionResult(
                success=True,
                canonical_url=url,
                title=meta.get("title"),
                creator_authors=meta.get("authors"),
                published_date=meta.get("published_date"),
                source_name=meta.get("site_name"),
                source_type="publisher",
                description=meta.get("description"),
                metadata=meta,
            )

        # Full text extraction
        full_text = _trafilatura_extract(html_bytes) or _bs4_extract(html_bytes)
        if not full_text:
            return ExtractionResult(success=False, canonical_url=url,
                                    error="Text extraction returned empty content")

        # Slice into article_section evidence pointers
        pointers = _slice_into_sections(full_text)

        return ExtractionResult(
            success=True,
            canonical_url=url,
            title=meta.get("title"),
            summary=full_text[:400] + "…" if len(full_text) > 400 else full_text,
            description=meta.get("description") or full_text[:200],
            creator_authors=meta.get("authors"),
            published_date=meta.get("published_date"),
            source_name=meta.get("site_name"),
            source_type="publisher",
            license=meta.get("license"),
            evidence_pointers=pointers,
            raw_text=full_text,
            metadata=meta,
        )


async def _fetch(url: str) -> Optional[bytes]:
    try:
        async with httpx.AsyncClient(timeout=15, follow_redirects=True,
                                     headers={"User-Agent": "RumuoBot/0.1 (+https://rumuo.com/bot)"}) as c:
            r = await c.get(url)
            if r.status_code == 200:
                return r.content
    except Exception:
        pass
    return None


def _extract_meta(html: bytes, url: str) -> dict:
    try:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html, "html.parser")
        def og(prop):
            return (soup.find("meta", property=prop) or {}).get("content", "")
        def name(n):
            return (soup.find("meta", attrs={"name": n}) or {}).get("content", "")
        title = (og("og:title") or
                 (soup.find("title") or {}).get_text(strip=True) or "")
        authors_raw = name("author") or og("article:author")
        return {
            "title":          title,
            "description":    og("og:description") or name("description"),
            "site_name":      og("og:site_name"),
            "published_date": og("article:published_time") or name("date"),
            "authors":        [authors_raw] if authors_raw else None,
            "license":        og("og:license") or name("license"),
            "canonical_url":  og("og:url") or url,
        }
    except Exception:
        return {}


def _trafilatura_extract(html: bytes) -> Optional[str]:
    try:
        import trafilatura
        return trafilatura.extract(html.decode("utf-8", errors="replace"))
    except Exception:
        return None


def _bs4_extract(html: bytes) -> Optional[str]:
    try:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html, "html.parser")
        for tag in soup(["script", "style", "nav", "footer", "header"]):
            tag.decompose()
        return soup.get_text(separator=" ", strip=True)
    except Exception:
        return None


def _slice_into_sections(text: str) -> list[EvidencePointer]:
    """Slice full text into article_section pointers of ~_SECTION_CHAR_LIMIT chars each."""
    pointers = []
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    buffer, buf_len = [], 0
    section_num = 0
    for para in paragraphs:
        buffer.append(para)
        buf_len += len(para)
        if buf_len >= _SECTION_CHAR_LIMIT:
            section_text = " ".join(buffer)
            pointers.append(EvidencePointer(
                pointer_type="article_section",
                pointer_value={"section": section_num},
                claim_text=section_text[:_SECTION_CHAR_LIMIT],
            ))
            section_num += 1
            buffer, buf_len = [], 0
    if buffer:
        pointers.append(EvidencePointer(
            pointer_type="article_section",
            pointer_value={"section": section_num},
            claim_text=" ".join(buffer)[:_SECTION_CHAR_LIMIT],
        ))
    return pointers
