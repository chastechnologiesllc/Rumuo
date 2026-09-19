import 'package:flutter/material.dart';
import '../models/channel.dart';

/// Production stub — channels now come from the Rumuo backend API.
/// The hard-coded YouTube channel list (Diary of CEO, Alex Hormozi, etc.)
/// has been removed: it was the wrong vertical (general business, not
/// Medicine / Nigeria). Once Phase A acquisition runs, channels are stored
/// in the `sources` table and served via the experience API.
class ChannelData {
  ChannelData._();

  // Empty — no hard-coded channels in production.
  static const List<Channel> all = [];
  static const List<Channel> combined = [];

  static final Map<String, Channel> byId = const {};

  /// Generic fallback used when a video's channelId has no DB entry yet.
  static const Channel fallback = Channel(
    id: 'rumuo',
    name: 'Rumuo',
    handle: '@rumuo',
    description: 'Knowledge discovery for professionals in Nigeria.',
    accentColor: Color(0xFFD4A843),
    category: 'Medicine',
    focus: 'Medical knowledge for Nigerian professionals',
    initials: 'R',
  );

  /// Build a Channel from a publisher name returned by the API.
  /// Used in place of ChannelData.byId lookups for API-sourced content.
  static Channel fromPublisher(String publisher) {
    final name = publisher.trim().isEmpty ? 'Rumuo' : publisher;
    return Channel(
      id: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
      name: name,
      handle: '@${name.toLowerCase().replaceAll(' ', '')}',
      description: name,
      accentColor: const Color(0xFFD4A843),
      category: 'Medicine',
      focus: 'Medical Knowledge',
      initials: name.isNotEmpty ? name[0].toUpperCase() : 'R',
    );
  }

  /// Returns empty list — no hard-coded channels to eager-fetch.
  /// Phase A acquisition populates channels via the DB.
  static List<Channel> eagerFor(Set<String> selectedCategoryIds) => const [];
}
