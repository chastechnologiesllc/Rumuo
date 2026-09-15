"""
agents/organizer/extraction/__init__.py

Extraction modules, one per information_form (ED-12 §1.1 form IDs).
Each extractor is called at pipeline stage 5 and returns a dict that
stage_5_extract() consumes.

MUST NOT: build one pipeline per form (ED-01 §4 item 9). One pipeline,
these are plug-in extractors for the content-specific pull at stage 5.
MUST NOT: extract beyond the access level determined at stage 3.
"""
from .base import BaseExtractor, ExtractionResult
from .video import VideoExtractor
from .audio import AudioExtractor
from .written import WrittenExtractor
from .structured_interactive import StructuredInteractiveExtractor
from .shorts import ShortsExtractor

# form_id → extractor class (matches information_forms rows seeded in DB)
EXTRACTOR_REGISTRY: dict[str, type[BaseExtractor]] = {
    "video":                  VideoExtractor,
    "shorts":                 ShortsExtractor,
    "audio":                  AudioExtractor,
    "written":                WrittenExtractor,
    "structured_interactive": StructuredInteractiveExtractor,
}


def get_extractor(form_id: str) -> BaseExtractor:
    """Return an extractor instance for the given information_form slug."""
    cls = EXTRACTOR_REGISTRY.get(form_id)
    if cls is None:
        raise ValueError(
            f"No extractor registered for form_id={form_id!r}. "
            f"Known forms: {list(EXTRACTOR_REGISTRY)}. "
            "Add the form to information_forms table (ED-12 §1.1) and register an extractor here."
        )
    return cls()
