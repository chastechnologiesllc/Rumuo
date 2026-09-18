"""
services/experience_api/schemas.py — Pydantic response schemas.

Field names and types are aligned with Flutter's ResourceRecord.fromJson
so the existing client requires no changes for the initial launch.

Flutter expects (ResourceApiService.dart):
  id, title, summary, url, content_type, publisher, region, license,
  trust_state, provenance_url, verified_at
"""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel


class ResourceRecord(BaseModel):
    """Single resource record — shape matches Flutter ResourceRecord.fromJson."""
    id: str                         # resource_id as string
    title: str
    summary: Optional[str] = None   # maps to resources.description
    url: Optional[str] = None       # maps to resources.canonical_url
    content_type: str = "resource"  # maps to resources.subtype ?? 'resource'
    publisher: str = "Unknown publisher"  # from sources.name (JOIN)
    region: str = "global"          # from resources.context.geography ?? 'global'
    license: Optional[str] = None
    trust_state: str = "discovered"
    provenance_url: Optional[str] = None  # from resources.provenance.url
    verified_at: Optional[str] = None
    # Extended fields for ED-07 §4 trust disclosure (new in this backend)
    trust_dimensions: Optional[Dict[str, Any]] = None
    field_confidence: Optional[Dict[str, Any]] = None
    type: Optional[str] = None      # information_form slug (video, audio, etc.)


class ResourcesResponse(BaseModel):
    data: List[ResourceRecord]
    meta: Dict[str, Any]
