"""
agents/researcher/channel_connectors/base.py
"""
from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional


@dataclass
class CandidateURL:
    url: str
    information_form: str           # form_id: video | shorts | audio | written | structured_interactive
    source_type: str                # source_type enum value
    source_name: str
    title: Optional[str] = None
    discovery_path: str = "channel_connector"
    confidence: float = 0.8


class BaseConnector(ABC):
    """Abstract base for all acquisition channel connectors."""

    @abstractmethod
    async def discover(self, query: str, limit: int = 20) -> list[CandidateURL]:
        """Search the channel for content matching query.

        Returns up to `limit` candidate URLs for intake.
        MUST NOT return URLs requiring auth/paywall bypass.
        """
        ...

    def _check_acquisition_gate(self) -> None:
        import os
        if os.environ.get("ACQUISITION_ACTIVE", "0") != "1":
            raise RuntimeError(
                "ACQUISITION_ACTIVE != '1'. "
                "Founder sign-off on LD-01 §3 required before any acquisition run."
            )
