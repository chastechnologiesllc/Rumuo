import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../screens/book_detail_screen.dart';
import '../theme/app_theme.dart';
import 'book_cover_image.dart';

/// The Books list — same rendering as the old Books tab, extracted so it
/// can be reused both from a standalone "Books" destination screen and
/// (later) from other entry points once real per-subcategory data exists.
class BooksList extends StatelessWidget {
  const BooksList({super.key});

  void _onTap(BuildContext context, Video video) {
    if (video.channelId == 'verified_book') {
      if ((video.freeSourceUrl ?? '').isEmpty) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: video)));
      return;
    }
    if (video.channelId == 'books') {

      Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: video)));
      return;
    }

  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<FeedProvider>().feedVideos;
    if (books.isEmpty) {
      return Center(
          child: Text('No books found.', style: Theme.of(context).textTheme.bodyMedium));
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => context.read<FeedProvider>().refresh(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: books.length,
        // ignore: deprecated_member_use
        cacheExtent: 400,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, idx) {
          final book = books[idx];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RepaintBoundary(
              key: ValueKey(book.id),
              child: GestureDetector(
                onTap: () => _onTap(context, book),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.dividerColor(context), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      BookCoverImage(
                        url: book.thumbnailUrl,
                        fallbackUrls: book.thumbnailFallbackUrls,
                        sourceUrl: book.freeSourceUrl,
                        width: 90,
                        height: 120,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(13),
                          bottomLeft: Radius.circular(13),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '📚 FREE BOOK',
                                  style: TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                book.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                book.description,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
