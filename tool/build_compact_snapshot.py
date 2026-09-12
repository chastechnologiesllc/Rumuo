#!/usr/bin/env python3
"""Build the small offline feed snapshot shipped by Rumuo.

The feed collector keeps a full raw snapshot for research/repair workflows.
The app only needs the general and hardcoded channels for offline first paint,
so this step removes long descriptions and unselected catalog history.
"""

import argparse
import json
import re
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument(
        '--output',
        default=Path('assets/data/feed_snapshot_compact.json'),
        type=Path,
    )
    parser.add_argument(
        '--general-output',
        default=Path('assets/data/resources/_general_boot.json'),
        type=Path,
    )
    parser.add_argument(
        '--general-catalog-output',
        default=Path('assets/data/resources/_general_catalog.json'),
        type=Path,
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    raw_general = json.loads((root / 'assets/data/resources/_general.json').read_text())
    boot = {
        'channels': raw_general.get('channels', []),
        'blogs': raw_general.get('blogs', []),
        'subcategorySources': raw_general.get('subcategorySources', []),
    }
    general_output = args.general_output
    if not general_output.is_absolute():
        general_output = root / general_output
    general_output.parent.mkdir(parents=True, exist_ok=True)
    general_output.write_text(json.dumps(boot, ensure_ascii=False, separators=(',', ':')) + '\n')

    catalog = {
        key: value for key, value in raw_general.items() if key != 'books'
    }
    catalog['books'] = [
        {
            key: book.get(key)
            for key in (
                'title',
                'author',
                'freeSourceUrl',
                'freeSourceType',
                'freeSourceNote',
                'coverUrl',
            )
            if book.get(key) is not None
        }
        for book in raw_general.get('books', [])
    ]
    catalog_output = args.general_catalog_output
    if not catalog_output.is_absolute():
        catalog_output = root / catalog_output
    catalog_output.parent.mkdir(parents=True, exist_ok=True)
    catalog_output.write_text(
        json.dumps(catalog, ensure_ascii=False, separators=(',', ':')) + '\n'
    )

    snapshot = json.loads(args.input.read_text())
    hardcoded_ids = set(re.findall(
        r"\bid:\s*'([A-Za-z0-9_-]{20,})'",
        (root / 'lib/data/channel_data.dart').read_text(),
    ))
    boot_ids = {entry.get('id') for entry in boot['channels'] if entry.get('id')}
    allowed_ids = hardcoded_ids | boot_ids

    compact = {'channels': {}}
    for channel_id, videos in (snapshot.get('channels') or {}).items():
        if channel_id not in allowed_ids:
            continue
        newest = sorted(
            videos,
            key=lambda video: video.get('publishedAt', ''),
            reverse=True,
        )[:15]
        compact['channels'][channel_id] = [
            {
                'id': video.get('id', ''),
                'title': video.get('title', ''),
                'description': '',
                'channelId': video.get('channelId') or channel_id,
                'channelName': video.get('channelName') or channel_id,
                'publishedAt': video.get('publishedAt', ''),
                'thumbnailUrl': video.get('thumbnailUrl', ''),
                'originalLink': video.get('originalLink'),
            }
            for video in newest
        ]

    # A scheduled refresh can temporarily receive no channel responses when
    # YouTube throttles the collector. Never let that transient network state
    # erase the last verified offline feed from the app bundle.
    if not compact['channels']:
        previous_path = root / 'assets/data/feed_snapshot_compact.json'
        if previous_path.exists():
            try:
                previous = json.loads(previous_path.read_text())
                previous_channels = previous.get('channels') or {}
                if previous_channels:
                    compact['channels'] = previous_channels
            except (OSError, json.JSONDecodeError):
                pass

    compact['blogs'] = [
        {
            'title': article.get('title', ''),
            'url': article.get('url', ''),
            'sourceName': article.get('sourceName', ''),
            'sourceUrl': article.get('sourceUrl'),
            'publishedAt': article.get('publishedAt', ''),
            'thumbnailUrl': article.get('thumbnailUrl'),
            'thumbnailFallbackUrls': (article.get('thumbnailFallbackUrls') or [])[:1],
            'description': '',
            'categoryId': article.get('categoryId'),
        }
        for article in list(snapshot.get('blogs') or [])[:120]
    ]

    output = args.output
    if not output.is_absolute():
        output = root / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(compact, ensure_ascii=False, separators=(',', ':')) + '\n')
    print(f'Wrote {output} ({output.stat().st_size} bytes)')
    print(f'Wrote {general_output} ({general_output.stat().st_size} bytes)')
    print(f'Wrote {catalog_output} ({catalog_output.stat().st_size} bytes)')


if __name__ == '__main__':
    main()
