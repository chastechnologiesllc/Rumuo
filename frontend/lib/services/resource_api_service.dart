import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/video.dart';

class ResourceRecord {
  final String id;
  final String title;
  final String summary;
  final Uri? url;
  final String contentType;
  final String publisher;
  final String region;
  final String? license;
  final String trustState;
  final Uri? provenanceUrl;
  final DateTime? verifiedAt;
  final String? type; // information_form slug: video, shorts, audio, written, structured_interactive

  const ResourceRecord({
    required this.id,
    required this.title,
    required this.summary,
    this.url,
    required this.contentType,
    required this.publisher,
    required this.region,
    this.license,
    required this.trustState,
    this.provenanceUrl,
    this.verifiedAt,
    this.type,
  });

  factory ResourceRecord.fromJson(Map<String, dynamic> json) {
    Uri? parseUri(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      try { return Uri.parse(s); } catch (_) { return null; }
    }
    return ResourceRecord(
      id:           json['id'] as String? ?? '',
      title:        json['title'] as String? ?? 'Untitled',
      summary:      json['summary'] as String? ?? '',
      url:          parseUri(json['url'] as String?),
      contentType:  json['content_type'] as String? ?? 'resource',
      publisher:    json['publisher'] as String? ?? 'Unknown publisher',
      region:       json['region'] as String? ?? 'global',
      license:      json['license'] as String?,
      trustState:   json['trust_state'] as String? ?? 'discovered',
      provenanceUrl: parseUri(json['provenance_url'] as String?),
      verifiedAt:   DateTime.tryParse(json['verified_at'] as String? ?? ''),
      type:         json['type'] as String?,
    );
  }

  /// Convert to Video for display in the feed.
  /// channelId is set based on the information_form type so that
  /// isShort and tab routing work correctly without touching the Video model.
  Video toVideo() {
    final form = type ?? contentType;
    final channelId = switch (form) {
      'shorts'                 => 'api_shorts',
      'audio'                  => 'api_audio',
      'written'                => 'api_written',
      'structured_interactive' => 'api_structured',
      _                        => 'api_videos', // video or unknown
    };
    return Video(
      id:           id,
      title:        title,
      description:  summary,
      channelId:    channelId,
      channelName:  publisher,
      publishedAt:  verifiedAt ?? DateTime(2024),
      thumbnailUrl: provenanceUrl?.toString() ?? '',
      originalLink: url?.toString(),
    );
  }
}

class ResourceApiService {
  const ResourceApiService();

  static const _defaultCountry  = 'NG';
  static const _defaultLanguage = 'en';
  static const _defaultLimit    = 40;
  static const _timeout         = Duration(seconds: 15);

  /// Fetch resources by subcategory slug.
  /// Returns empty list when the API URL is not configured or on any error.
  Future<List<ResourceRecord>> list({
    String? subcategory,
    String query = '',
    String country = _defaultCountry,
    String language = _defaultLanguage,
    int limit = _defaultLimit,
    int offset = 0,
  }) async {
    final base = AppConfig.resourceApiBaseUrl.trim();
    if (base.isEmpty) return const [];
    try {
      final uri = Uri.parse(base).replace(queryParameters: {
        if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
        if (query.trim().isNotEmpty)                       'q': query.trim(),
        'country':  country,
        'language': language,
        'limit':    '$limit',
        'offset':   '$offset',
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final payload  = jsonDecode(response.body) as Map<String, dynamic>;
      final rows     = payload['data'] as List<dynamic>? ?? const [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(ResourceRecord.fromJson)
          .where((r) => r.id.isNotEmpty && r.title.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Convenience: fetch and map to Video in one call.
  Future<List<Video>> listAsVideos({
    String? subcategory,
    String query = '',
    String country = _defaultCountry,
    String language = _defaultLanguage,
    int limit = _defaultLimit,
  }) async {
    final records = await list(
      subcategory: subcategory,
      query: query,
      country: country,
      language: language,
      limit: limit,
    );
    return records.map((r) => r.toVideo()).toList(growable: false);
  }

  /// Health check — returns true when the API responds.
  Future<bool> ping() async {
    final base = AppConfig.resourceApiBaseUrl.trim();
    if (base.isEmpty) return false;
    try {
      final healthUrl = base.replaceFirst(RegExp(r'/api/resources.*'), '/health');
      final r = await http.get(Uri.parse(healthUrl)).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
