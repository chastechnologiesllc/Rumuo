"""
agents/organizer/extraction/shorts.py — extractor for form_id='shorts'.

Short-form video: YouTube Shorts, social media clips, reels.
Evidence pointers are transcript_segment slices (typically just one segment
given the short duration).
"""
from __future__ import annotations
from typing import Optional

from .base import BaseExtractor, EvidencePointer, ExtractionResult
from .video import _youtube_id, _fetch_oembed_meta, _fetch_transcript


class ShortsExtractor(BaseExtractor):

    async def extract(self, url: str, access_mode: str,
                      raw: Optional[bytes] = None) -> ExtractionResult:
        if access_mode == "skip":
            return ExtractionResult(success=True, canonical_url=url)
        if access_mode == "link_out_only":
            return self._link_out_result(url)

        yt_id = _youtube_id(url)
        meta = await _fetch_oembed_meta(url, yt_id)

        if access_mode == "metadata_only":
            return ExtractionResult(
                success=True, canonical_url=url,
                title=meta.get("title"),
                creator_authors=[meta["author_name"]] if meta.get("author_name") else None,
                source_name=meta.get("provider_name", "YouTube" if yt_id else "Unknown"),
                source_type="platform" if yt_id else "creator",
                metadata=meta,
            )

        transcript_segs = await _fetch_transcript(yt_id) if yt_id else []
        raw_text = " ".join(s["text"] for s in transcript_segs)

        pointers = [
            EvidencePointer(
                pointer_type="transcript_segment",
                pointer_value={"start_ms": s["start_ms"], "end_ms": s["end_ms"]},
                claim_text=s["text"],
            )
            for s in transcript_segs
        ]

        return ExtractionResult(
            success=True, canonical_url=url,
            title=meta.get("title"),
            summary=raw_text[:300] or None,
            creator_authors=[meta["author_name"]] if meta.get("author_name") else None,
            source_name=meta.get("provider_name", "YouTube" if yt_id else "Unknown"),
            source_type="platform" if yt_id else "creator",
            evidence_pointers=pointers,
            raw_text=raw_text,
            metadata=meta,
        )
