"""
agents/organizer/extraction/base.py — shared extractor contract.

Every form extractor inherits BaseExtractor and implements extract().
The pipeline calls get_extractor(form_id).extract(url, access_mode, raw)
and receives an ExtractionResult — no form-specific branching in pipeline code.
"""
from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Optional


@dataclass
class EvidencePointer:
    pointer_type: str           # transcript_segment | article_section | page | table | dataset_field | other
    pointer_value: dict         # {start_ms, end_ms} for video; {page, paragraph} for written; etc.
    claim_text: str             # the claim extracted at this pointer


@dataclass
class ExtractionResult:
    success: bool
    summary: Optional[str] = None
    description: Optional[str] = None
    evidence_pointers: list[EvidencePointer] = field(default_factory=list)
    # Identified fields passed to stage 2
    title: Optional[str] = None
    creator_authors: Optional[list[str]] = None
    published_date: Optional[str] = None       # ISO date string
    languages: Optional[list[str]] = None
    source_name: Optional[str] = None
    source_type: Optional[str] = None          # source_type enum value
    # Normalised fields passed to stage 4
    canonical_url: Optional[str] = None
    external_identifiers: Optional[dict] = None
    license: Optional[str] = None
    rights_info: Optional[str] = None
    attribution_requirements: Optional[str] = None
    # Raw extras the classification stage can use
    raw_text: Optional[str] = None
    metadata: dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None


class BaseExtractor(ABC):
    """Abstract base. Subclasses implement extract() for their information_form."""

    @abstractmethod
    async def extract(
        self,
        url: str,
        access_mode: str,           # full | metadata_only | link_out_only | skip
        raw: Optional[bytes] = None,
    ) -> ExtractionResult:
        """Pull content/metadata from url within the constraints of access_mode.

        access_mode='full'         — fetch and parse the full content.
        access_mode='metadata_only'— fetch only publicly visible headers/meta tags.
        access_mode='link_out_only'— record the URL; no content fetch at all.
        access_mode='skip'         — resource is removed; return empty result.

        MUST NOT attempt content beyond access_mode allows (ED-01 §4 item 1).
        """
        ...

    def _metadata_only_result(self, url: str, title: str = "") -> ExtractionResult:
        """Shorthand for metadata-only extraction (no content fetched)."""
        return ExtractionResult(
            success=True,
            canonical_url=url,
            title=title or "[metadata only — title not yet resolved]",
            description="[Content access restricted — metadata-only index entry]",
        )

    def _link_out_result(self, url: str) -> ExtractionResult:
        """Shorthand for link-out-only (no fetch at all)."""
        return ExtractionResult(
            success=True,
            canonical_url=url,
            title="[link-out only]",
            description="[Restricted access — linked without content extraction]",
        )
