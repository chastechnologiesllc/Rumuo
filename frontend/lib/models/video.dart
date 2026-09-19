class Video {
  final String id;
  final String title;
  final String description;
  final String channelId;
  final String channelName;
  final DateTime publishedAt;
  final String thumbnailUrl;

  /// Ordered fallback cover URLs for book-like videos.
  final List<String> thumbnailFallbackUrls;

  /// Original link — YouTube Shorts have /shorts/ in this URL.
  /// For API-sourced resources this is the canonical resource URL.
  final String? originalLink;

  // Book-only fields
  final String? freeSourceUrl;
  final String? freeSourceType; // 'web' or 'download'
  final String? sourceCategoryId;

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.channelId,
    required this.channelName,
    required this.publishedAt,
    required this.thumbnailUrl,
    this.thumbnailFallbackUrls = const [],
    this.originalLink,
    this.freeSourceUrl,
    this.freeSourceType,
    this.sourceCategoryId,
  });

  /// True if this video is a short-form clip.
  /// API-sourced shorts use channelId == 'api_shorts'.
  /// YouTube Shorts are detected from the /shorts/ URL path.
  bool get isShort {
    if (channelId == 'api_shorts') return true;
    if (originalLink != null && originalLink!.contains('/shorts/')) return true;
    final t = title.toLowerCase();
    final d = description.toLowerCase();
    return t.contains('#shorts') ||
        t.contains('#short') ||
        d.contains('#shorts') ||
        d.contains('#short') ||
        d.contains('/shorts/') ||
        d.contains('youtube.com/shorts');
  }

  /// For API-sourced resources, watchUrl is the canonical resource URL.
  String get watchUrl {
    if (channelId.startsWith('api_')) return originalLink ?? '';
    return isShort
        ? 'https://www.youtube.com/shorts/$id'
        : 'https://www.youtube.com/watch?v=$id';
  }

  /// API resources use thumbnailUrl directly (no YouTube img.youtube.com).
  bool get _isBookLike =>
      channelId == 'books' ||
      channelId == 'verified_book' ||
      channelId.startsWith('api_');

  String get thumbnailHd =>
      _isBookLike ? thumbnailUrl : 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
  String get thumbnailMq =>
      _isBookLike ? thumbnailUrl : 'https://img.youtube.com/vi/$id/mqdefault.jpg';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'channelId': channelId,
        'channelName': channelName,
        'publishedAt': publishedAt.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
        if (thumbnailFallbackUrls.isNotEmpty)
          'thumbnailFallbackUrls': thumbnailFallbackUrls,
        if (originalLink != null) 'originalLink': originalLink,
        if (freeSourceUrl != null) 'freeSourceUrl': freeSourceUrl,
        if (freeSourceType != null) 'freeSourceType': freeSourceType,
        if (sourceCategoryId != null) 'sourceCategoryId': sourceCategoryId,
      };

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        channelId: json['channelId'] as String,
        channelName: json['channelName'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        thumbnailUrl: json['thumbnailUrl'] as String,
        thumbnailFallbackUrls: (json['thumbnailFallbackUrls'] as List?)
                ?.whereType<String>()
                .where((u) => u.trim().isNotEmpty)
                .toList(growable: false) ??
            const [],
        originalLink: json['originalLink'] as String?,
        freeSourceUrl: json['freeSourceUrl'] as String?,
        freeSourceType: json['freeSourceType'] as String?,
        sourceCategoryId: json['sourceCategoryId'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Video && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
