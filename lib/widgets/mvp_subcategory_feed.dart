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
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 600;
          return ShimmerLoader(
            variant: desktop ? ShimmerVariant.grid : ShimmerVariant.videoFeed,
            columns: desktop && widget.form == InformationForm.shorts ? 4 : 3,
          );
        },
      );
    }
    if (videos.isEmpty && sources.isEmpty) {
      return _emptyState(context, provider);
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemCount = videos.length + sources.length;
          final desktop = constraints.maxWidth >= 600;
          final shortsDesktop = desktop && widget.form == InformationForm.shorts;
          final padding = const EdgeInsets.fromLTRB(16, 12, 16, 120);

          Widget card(int index) {
            if (index < videos.length) {
              final video = videos[index];
              final channel =
                  ChannelData.byId[video.channelId] ?? ChannelData.fallback;
              final tag = widget.form == InformationForm.shorts
                  ? 'Clips'
                  : 'Long-form';
              return InlineVideoCard(
                video: video,
                channel: channel,
                subcategoryTag: tag,
                saved: provider.isVideoSaved(video.id),
                activeVideoNotifier: _activeVideoNotifier,
                onSave: () => provider.toggleSaved(video),
                onShare: () {},
              );
            }
            return _SourceCard(source: sources[index - videos.length]);
          }

          if (desktop) {
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: shortsDesktop ? 4 : 3,
                crossAxisSpacing: shortsDesktop ? 10 : 14,
                mainAxisSpacing: shortsDesktop ? 10 : 14,
                childAspectRatio: shortsDesktop ? 0.62 : 1.08,
              ),
              itemCount: itemCount,
              itemBuilder: (_, index) => card(index),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            itemCount: itemCount,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: card(index),
            ),
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
          thumbnailUrl: _faviconFor(blog['url'] ?? ''),
          description: 'Verified written source with current articles and updates.',
          contentType: 'Written blog source',
          region: 'Global',
        ));
      }
      for (final book in ResourceCategoryData.verifiedBooks.take(40)) {
        result.add(VerifiedSubcategorySource(
          subcategoryId: 'written_books',
          subcategoryName: book.author,
          title: book.title,
          url: book.freeSourceUrl,
          thumbnailUrl: book.coverUrl,
          description: book.freeSourceNote ?? 'Verified free book or guide.',
          contentType: 'Written book or guide',
          region: book.region ?? 'Global',
        ));
      }
      return result;
    }
    return const [];
  }

  static String? _faviconFor(String url) {
    final host = Uri.tryParse(url)?.host;
    return host == null || host.isEmpty
        ? null
        : 'https://www.google.com/s2/favicons?domain=$host&sz=256';
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
    if (source.thumbnailUrl?.trim().isNotEmpty == true) {
      return source.thumbnailUrl!;
    }
    final host = Uri.tryParse(source.url)?.host ?? '';
    return host.isEmpty
        ? ''
        : 'https://www.google.com/s2/favicons?domain=$host&sz=256';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor(context), width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800, height: 1.28)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.account_circle_rounded,
                            size: 20, color: AppTheme.gold),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(source.subcategoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                        Icon(Icons.more_vert_rounded,
                            size: 19, color: AppTheme.textMuted(context)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
