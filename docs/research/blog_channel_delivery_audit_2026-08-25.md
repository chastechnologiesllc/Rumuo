# Blog and Channel Delivery Audit — 25 August 2026

## Verified runtime findings

The General catalog currently contains 12 hard-coded channels in `lib/data/channel_data.dart` plus category-loaded channels from the resource JSON files. Direct probes of the 12 hard-coded YouTube Atom endpoints returned HTTP 200 with non-empty XML responses. The native channel path therefore has valid source IDs and a usable direct endpoint.

The Web channel path was failing at the CORS proxy layer. Direct probes showed `corsproxy.io` returning HTTP 403 with the `keyless_legacy_url` error when the app used the bare form `https://corsproxy.io/?<encoded-url>`. The current CORSPROXY documentation shows the supported form as `https://corsproxy.io/?url=<encoded-url>` and states that production domains may require authorization depending on the service tier. The code has been updated to use the documented `?url=` form, with the existing `api.allorigins.win` fallback retained.

The same malformed proxy form existed in four runtime locations: YouTube RSS in `RssService`, YouTube channel-page history in `YoutubeChannelService`, aggregated blog feed/page requests in `BlogRssService`, and Web article HTML loading in `BlogReaderScreen`. All four must use the documented parameter format.

The Blogs tab was also not using the full verified catalog on Web. `BlogRssService.fetchAll()` used only the five hard-coded feeds when `kIsWeb`, which silently excluded the 10 General catalog blogs and selected category blogs. The repair changes both Web and native paths to use the deduplicated `combinedBlogFeeds` list with a bounded worker pool.

Two hard-coded general blog URLs were not currently usable as feeds: `https://www.forbes.com/entrepreneurs/feed/` returned HTTP 404 HTML, and `https://feeds.hbr.org/harvardbusiness` did not return a usable response from the probe environment. `https://www.forbes.com/business/feed/` returned valid RSS XML, and `https://www.fastcompany.com/rss` returned valid RSS XML. The runtime list now uses those reachable official endpoints instead.

The existing General catalog blog URLs include several homepage URLs, such as Greater Good Magazine, Farnam Street, Ness Labs, The Decision Lab, and Smithsonian Magazine. `BlogRssService` already supports HTML RSS/Atom autodiscovery and conventional feed paths. The repair preserves that behavior while ensuring those catalog sources are actually fetched on Web.

The primary shell’s second navigation item is currently named `Shorts` and mounts `ChannelsScreen`, which is a Shorts-only grid. Per-channel browsing remains available through `ChannelVideosScreen` from category and search surfaces. This navigation distinction should be preserved unless the product requirement explicitly changes the tab from Shorts to a channel directory; the immediate unavailable issue is addressed in the underlying channel fetch path and Web proxy format.

## Sources

1. [CORSPROXY documentation and endpoint examples](https://corsproxy.io/)
2. [CORS proxy reference list](https://gist.github.com/jimmywarting/ac1be6ea0297c16c477e17f8fbe51347)
3. [CORS Anywhere repository and client URL format](https://github.com/Rob--W/cors-anywhere)
4. [Harvard Business Review home page](https://hbr.org/)
5. [Harvard Business Review RSS syndication information](https://store.hbr.org/rss-syndication/)
6. [Harvard Business Review feed reference](https://tagteam.harvard.edu/hubs/11/hub_feeds/924)
7. [Forbes RSS information](https://www.forbes.com/static_html/rss/rsshelp_header.html)

## Durable Web fallback implementation

A direct retest showed that the corrected `corsproxy.io/?url=` format is still restricted for production domains without an authorized account, returning HTTP 403 with `Free usage is limited to localhost and development environments`. The earlier bare-query format was also invalid. Public proxy services are therefore treated as opportunistic live sources, not as the only delivery path.

The repository now includes `tool/feed_snapshot_builder.py`, which fetches the public YouTube Atom feeds for the deduplicated catalog and the verified General blog sources. Scheduled refreshes write a temporary full snapshot, then `tool/build_compact_snapshot.py` keeps only the general first-paint window in `assets/data/feed_snapshot_compact.json` and `assets/data/resources/_general_boot.json`. This preserves a same-origin recovery path without shipping the multi-megabyte research archive to every opening Web client.

`FeedSnapshotService` loads the bundled JSON with Flutter’s same-origin asset loader. `RssService` uses it after live RSS, retries, and stale disk cache fail; `BlogRssService` reads the compact blog window only when all live feeds fail. This means Web has a usable public-content recovery path even when CORS proxies are blocked, while native builds continue to prefer direct live feeds.
