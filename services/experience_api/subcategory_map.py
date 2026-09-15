"""
services/experience_api/subcategory_map.py

Maps Flutter SubcategoryData slugs (subcategory.dart) to
(information_forms.form_id, optional subtype) pairs.

Flutter slugs: videos_long_form, videos_interviews, videos_lectures,
videos_documentaries, videos_webinars, shorts_clips, shorts_explanations,
shorts_highlights, shorts_demos, audio_podcasts, audio_lectures, etc.

form_id values MUST match information_forms rows in the DB — seeded
in 001_initial_schema.sql as: video, shorts, audio, written, structured_interactive.
"""
from typing import Optional, Tuple


# (flutter_subcategory_slug) → (form_id, subtype_filter_or_None)
_SUBCATEGORY_MAP: dict[str, Tuple[str, Optional[str]]] = {
    # ── Video ─────────────────────────────────────────────────────────────
    "videos_long_form":      ("video", "long_form"),
    "videos_interviews":     ("video", "interview"),
    "videos_lectures":       ("video", "lecture"),
    "videos_documentaries":  ("video", "documentary"),
    "videos_webinars":       ("video", "webinar"),
    # ── Shorts ────────────────────────────────────────────────────────────
    "shorts_clips":          ("shorts", "clip"),
    "shorts_explanations":   ("shorts", "explanation"),
    "shorts_highlights":     ("shorts", "highlight"),
    "shorts_demos":          ("shorts", "demo"),
    # ── Audio ─────────────────────────────────────────────────────────────
    "audio_podcasts":        ("audio", "podcast"),
    "audio_lectures":        ("audio", "lecture"),
    "audio_interviews":      ("audio", "interview"),
    "audio_audiobooks":      ("audio", "audiobook"),
    "audio_debates":         ("audio", "debate"),
    # ── Written ───────────────────────────────────────────────────────────
    "written_papers":        ("written", "paper"),
    "written_blogs":         ("written", "blog"),
    "written_books":         ("written", "book"),
    "written_case_studies":  ("written", "case_study"),
    "written_guides":        ("written", "guide"),
    # ── Structured / Interactive ──────────────────────────────────────────
    "structured_courses":    ("structured_interactive", "course"),
    "structured_datasets":   ("structured_interactive", "dataset"),
    "structured_tools":      ("structured_interactive", "tool"),
    "structured_simulations":("structured_interactive", "simulation"),
    "structured_qa":         ("structured_interactive", "qa"),
}


def resolve_subcategory(slug: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    """Convert a Flutter subcategory slug to (form_id, subtype).

    Returns (None, None) when slug is absent or unrecognised,
    which causes the query layer to return across all form types.
    """
    if not slug:
        return None, None
    return _SUBCATEGORY_MAP.get(slug, (None, None))
