"""
agents/organizer/extraction/video.py — extractor for form_id='video'.

Handles YouTube videos and direct video URLs.
Full access: fetch transcript/captions → slice into evidence pointer segments.
Metadata only: fetch oEmbed / Open Graph title, channel, date.
"""
from __future__ import annotations
import re
from typing import Optional

import httpx

from .base import BaseExtractor, EvidencePointer, ExtractionResult

# Segment length for transcript evidence pointers (seconds)
_SEGMENT_SECONDS = 120


class VideoExtractor(BaseExtractor):

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

        yt_id = _youtube_id(url)

        if access_mode == "metadata_only":
            meta = await _fetch_oembed_meta(url, yt_id)
            return ExtractionResult(
                success=True,
                canonical_url=url,
                title=meta.get("title"),
                creator_authors=[meta["author_name"]] if meta.get("author_name") else None,
                source_name=meta.get("provider_name", "YouTube" if yt_id else "Unknown"),
                source_type="platform" if yt_id else "publisher",
                metadata=meta,
            )

        # Full extraction
        meta = await _fetch_oembed_meta(url, yt_id)
        transcript_segments = await _fetch_transcript(yt_id) if yt_id else []

        evidence_pointers = [
            EvidencePointer(
                pointer_type="transcript_segment",
                pointer_value={"start_ms": seg["start_ms"], "end_ms": seg["end_ms"]},
                claim_text=seg["text"],
            )
            for seg in transcript_segments
        ]

        return ExtractionResult(
            success=True,
            canonical_url=url,
            title=meta.get("title"),
            summary=_build_summary(transcript_segments),
            creator_authors=[meta["author_name"]] if meta.get("author_name") else None,
            source_name=meta.get("provider_name", "YouTube" if yt_id else "Unknown"),
            source_type="platform" if yt_id else "publisher",
            evidence_pointers=evidence_pointers,
            raw_text=" ".join(s["text"] for s in transcript_segments),
            metadata=meta,
        )


def _youtube_id(url: str) -> Optional[str]:
    patterns = [
        r"(?:v=|youtu\.be/)([A-Za-z0-9_-]{11})",
        r"embed/([A-Za-z0-9_-]{11})",
    ]
    for p in patterns:
        m = re.search(p, url)
        if m:
            return m.group(1)
    return None


async def _fetch_oembed_meta(url: str, yt_id: Optional[str]) -> dict:
    """Fetch oEmbed metadata — title, author, provider."""
    oembed_url = (
        f"https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={yt_id}&format=json"
        if yt_id else
        f"https://noembed.com/embed?url={url}"
    )
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(oembed_url)
            if r.status_code == 200:
                return r.json()
    except Exception:
        pass
    return {}


async def _fetch_transcript(yt_id: str) -> list[dict]:
    """Fetch YouTube captions/transcript via youtube-transcript-api if available.

    Returns list of {start_ms, end_ms, text} dicts.
    Falls back to empty list if captions are unavailable.
    """
    try:
        from youtube_transcript_api import YouTubeTranscriptApi
        entries = YouTubeTranscriptApi.get_transcript(yt_id)
        segments = []
        chunk_text, chunk_start = [], None
        chunk_duration = 0.0
        for e in entries:
            if chunk_start is None:
                chunk_start = e["start"]
            chunk_text.append(e["text"])
            chunk_duration += e.get("duration", 0)
            if chunk_duration >= _SEGMENT_SECONDS:
                segments.append({
                    "start_ms": int(chunk_start * 1000),
                    "end_ms":   int((chunk_start + chunk_duration) * 1000),
                    "text":     " ".join(chunk_text),
                })
                chunk_text, chunk_start, chunk_duration = [], None, 0.0
        if chunk_text:
            segments.append({
                "start_ms": int((chunk_start or 0) * 1000),
                "end_ms":   int(((chunk_start or 0) + chunk_duration) * 1000),
                "text":     " ".join(chunk_text),
            })
        return segments
    except Exception:
        return []


def _build_summary(segments: list[dict]) -> Optional[str]:
    if not segments:
        return None
    all_text = " ".join(s["text"] for s in segments)
    return all_text[:500] + "…" if len(all_text) > 500 else all_text
