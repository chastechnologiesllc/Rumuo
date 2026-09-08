import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/channel_data.dart';
import '../data/resource_category_data.dart';
import '../models/information_form.dart';
import '../models/resource_category.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../screens/blog_reader_screen.dart';
import '../theme/app_theme.dart';
import 'inline_video_card.dart';
import 'shimmer_loader.dart';

/// Category feed that never substitutes one content type for another:
/// videos/shorts use the real video pool, Written uses real books/blogs, and
/// Audio/Datasets use verified subcategory source records.
class MvpSubcategoryFeed extends StatefulWidget {
  final InformationForm form;

  const MvpSubcategoryFeed({required this.form, super.key});

  @override
  State<MvpSubcategoryFeed> createState() => _MvpSubcategoryFeedState();
}

class _MvpSubcategoryFeedState extends State<MvpSubcategoryFeed> {
  final _activeVideoNotifier = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _activeVideoNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final videos = _videoContent(provider);
    final sources = _sourceContent();

    if (provider.state == FeedState.loading && videos.isEmpty && sources.isEmpty) {
      return const ShimmerLoader();
    }
    if (videos.isEmpty && sources.isEmpty) {
      return _emptyState(context, provider);
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: videos.length + sources.length,
        itemBuilder: (context, index) {
          if (index < videos.length) {
            final video = videos[index];
            final channel = ChannelData.byId[video.channelId] ?? ChannelData.fallback;
            final tag = widget.form == InformationForm.shorts ? 'Clips' : 'Long-form';
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InlineVideoCard(
                video: video,
                channel: channel,
                subcategoryTag: tag,
                saved: provider.isVideoSaved(video.id),
                activeVideoNotifier: _activeVideoNotifier,
                onSave: () => provider.toggleSaved(video),
                onShare: () {},
              ),
            );
          }
          final source = sources[index - videos.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SourceCard(source: source),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context, FeedProvider provider) =>
      RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: () => provider.refresh(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'No ${widget.form.label} content available yet. Pull to refresh.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );

  List<Video> _videoContent(FeedProvider provider) {
    if (widget.form != InformationForm.videos &&
        widget.form != InformationForm.shorts) {
      return const [];
    }
    final all = provider.allFeedVideos
        .where((video) => video.channelId != 'books' && video.channelId != 'verified_book');
    return widget.form == InformationForm.shorts
        ? all.where((video) => video.isShort).toList()
        : all.where((video) => !video.isShort).toList();
  }

  List<VerifiedSubcategorySource> _sourceContent() {
    if (widget.form == InformationForm.audio ||
        widget.form == InformationForm.structured) {
      final prefix = widget.form == InformationForm.audio ? 'audio_' : 'structured_';
      return ResourceCategoryData.verifiedSubcategorySources
          .where((source) => source.subcategoryId.startsWith(prefix))
          .toList(growable: false);
    }
    if (widget.form == InformationForm.written) {
      final result = <VerifiedSubcategorySource>[];
      for (final blog in ResourceCategoryData.verifiedBlogs) {
        result.add(VerifiedSubcategorySource(
          subcategoryId: 'written_blogs',
          subcategoryName: 'Blogs',
          title: blog['name'] ?? 'Blog source',
          url: blog['url'] ?? '',
          description: 'Verified written source with current articles and updates.',
          contentType: 'Written blog source',
          region: 'Global',
        ));
      }
      for (final book in ResourceCategoryData.verifiedBooks.take(40)) {
        result.add(VerifiedSubcategorySource(
          subcategoryId: 'written_books',
          subcategoryName: 'Books',
          title: book.title,
          url: book.freeSourceUrl,
          description: book.freeSourceNote ?? 'Verified free book or guide.',
          contentType: 'Written book or guide',
          region: book.region ?? 'Global',
        ));
      }
      return result;
    }
    return const [];
  }
}

class _SourceCard extends StatelessWidget {
  final VerifiedSubcategorySource source;

  const _SourceCard({required this.source});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(source.url);
    if (uri == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlogReaderScreen(
        url: source.url,
        title: source.title,
        sourceName: source.subcategoryName,
        thumbnailUrl: _thumbnailUrl,
        excerpt: source.description,
      ),
    ));
  }

  String get _thumbnailUrl {
    final host = Uri.tryParse(source.url)?.host ?? '';
    return host.isEmpty
        ? ''
        : 'https://www.google.com/s2/favicons?domain=$host&sz=256';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor(context), width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 7,
                      child: Image.network(
                        _thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.gold.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: const Icon(Icons.public_rounded,
                              color: AppTheme.gold, size: 34),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          child: Text(source.subcategoryName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(source.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(source.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted(context), height: 1.4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(source.contentType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted(context))),
                  const Spacer(),
                  const Icon(Icons.open_in_new_rounded,
                      size: 17, color: AppTheme.gold),
                ],
              ),
            ],
          ),
        ),
      );
}
