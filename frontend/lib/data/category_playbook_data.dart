import '../models/video.dart';
import 'book_insights_data.dart';

/// Production playbook facade.
///
/// Playbook content is served by the Rumuo API. The compatibility methods
/// remain so older screens can safely render an empty state while the API is
/// unavailable; no hard-coded mock content is embedded in the app.
class CategoryPlaybookData {
  CategoryPlaybookData._();

  static const List<Video> videos = <Video>[];
  static const List<BookInsightData> insights = <BookInsightData>[];
  static const List<Object> all = <Object>[];

  static String playbookId(String categoryId) => 'playbook_$categoryId';

  static bool isPlaybookId(String videoId) => videoId.startsWith('playbook_');

  static BookInsightData? findAnyInsight(String bookId) =>
      BookInsightData.findInsight(bookId);
}
