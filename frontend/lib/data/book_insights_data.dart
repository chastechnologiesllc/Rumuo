/// Production stub — book content comes from the Rumuo backend API
/// (resources with type='written'). The hard-coded book insights list
/// (Think and Grow Rich, Rich Dad Poor Dad, etc.) was not Medicine
/// content and has been removed.
class BookChapter {
  final String title;
  final String body;
  final List<String> keyPoints;
  const BookChapter({
    required this.title,
    required this.body,
    this.keyPoints = const [],
  });
}

class BookInsightData {
  final String id;
  final String title;
  final String author;
  final String tagline;
  final String intro;
  final List<BookChapter> chapters;
  final String purchaseUrl;
  const BookInsightData({
    required this.id,
    required this.title,
    required this.author,
    required this.tagline,
    required this.intro,
    required this.chapters,
    required this.purchaseUrl,
  });

  static BookInsightData? findInsight(String id) => null;
}

/// Empty — no hard-coded book insights in production.
const List<BookInsightData> kBookInsights = [];
