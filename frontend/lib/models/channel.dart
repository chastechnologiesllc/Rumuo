import 'package:flutter/material.dart';

class Channel {
  final String id;
  final String name;
  final String handle;
  final String description;
  final Color accentColor;
  final String category;
  final String focus;
  final String initials;

  /// Links this channel to one of the Rumuo taxonomy categories.
  /// Populated from the DB via the experience API.
  final String? resourceCategoryId;

  const Channel({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.accentColor,
    required this.category,
    required this.focus,
    required this.initials,
    this.resourceCategoryId,
  });

  String get rssUrl =>
      'https://www.youtube.com/feeds/videos.xml?channel_id=$id';

  String get channelUrl => 'https://www.youtube.com/channel/$id';

  /// Avatar URL — sourced from the `sources` table via the API.
  /// Returns null until the source record is fetched.
  String? get avatarUrl => null;

  String get youtubeHandle {
    final value = handle.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (value.startsWith('@') && !value.contains(' ')) {
      return 'https://www.youtube.com/$value';
    }
    return channelUrl;
  }
}
