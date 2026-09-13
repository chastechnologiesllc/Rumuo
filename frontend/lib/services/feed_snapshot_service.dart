import '../models/video.dart';

/// Deterministic offline source used by the frontend while real resources are
/// intentionally unavailable. Content cards are supplied by Dart mock data.
class FeedSnapshotService {
  FeedSnapshotService._();
  static final FeedSnapshotService instance = FeedSnapshotService._();

  Future<List<Video>> channelVideos(String _) async => const [];

  Future<List<Map<String, dynamic>>> blogArticles() async => const [];

  void clearMemory() {}
}
