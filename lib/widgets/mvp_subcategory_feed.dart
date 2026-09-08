import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/channel_data.dart';
import '../data/subcategory_data.dart';
import '../models/information_form.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import 'inline_video_card.dart';
import 'shimmer_loader.dart';

/// A real content stream for a primary category. It reads the existing
/// FeedProvider pool; the only MVP metadata added here is the subcategory tag.
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
    final videos = _contentFor(provider);

    if (provider.state == FeedState.loading && videos.isEmpty) {
      return const ShimmerLoader();
    }
    if (videos.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: () => provider.refresh(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'No content available yet. Pull to refresh.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final subcategories = SubcategoryData.forForm(widget.form);
    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          final channel = ChannelData.byId[video.channelId] ?? ChannelData.fallback;
          final tag = subcategories[index % subcategories.length].name;
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
        },
      ),
    );
  }

  List<Video> _contentFor(FeedProvider provider) {
    final all = provider.allFeedVideos
        .where((video) => video.channelId != 'books' && video.channelId != 'verified_book')
        .toList();
    switch (widget.form) {
      case InformationForm.videos:
        return all.where((video) => !video.isShort).toList();
      case InformationForm.shorts:
        return all.where((video) => video.isShort).toList();
      case InformationForm.audio:
      case InformationForm.written:
      case InformationForm.structured:
        // These information forms do not yet have separate backend content
        // types. Until those sources land, show the real loaded content pool
        // rather than fabricated cards, while preserving the subcategory tag.
        return all;
    }
  }
}
