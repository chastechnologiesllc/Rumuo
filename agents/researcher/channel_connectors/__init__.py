"""
agents/researcher/channel_connectors/__init__.py

One connector per approved acquisition channel (LD-03 §4).
Each connector implements discover(query) -> list[CandidateURL].

MUST NOT: bypass authentication, paywalls, or platform access protections.
MUST NOT: activate without ACQUISITION_ACTIVE=1 (founder sign-off gate).
"""
from .base import BaseConnector, CandidateURL
from .youtube_api import YouTubeConnector
from .web_crawl import WebCrawlConnector
from .rss import RSSConnector
from .openalex import OpenAlexConnector

CONNECTOR_REGISTRY: dict[str, type[BaseConnector]] = {
    "youtube_api":   YouTubeConnector,
    "web_crawl":     WebCrawlConnector,
    "rss":           RSSConnector,
    "openalex_api":  OpenAlexConnector,
}


def get_connector(channel: str) -> BaseConnector:
    cls = CONNECTOR_REGISTRY.get(channel)
    if cls is None:
        raise ValueError(
            f"No connector for channel={channel!r}. "
            f"Registered: {list(CONNECTOR_REGISTRY)}. "
            "Add the channel to medicine_nigeria.yaml and register it here."
        )
    return cls()
