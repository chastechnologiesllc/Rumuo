import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/channel_data.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import 'inline_video_card.dart';
import 'shimmer_loader.dart';

/// The Videos feed list — same rendering as the old Videos tab, extracted
/// so it can be reused both from a standalone "Videos" destination screen
/// and (later) filtered per subcategory once that data exists.
class VideoFeedList extends StatefulWidget {
  const VideoFeedList({super.key});

  @override
  State<VideoFeedList> createState() => _VideoFeedListState();
}

class _VideoFeedListState extends State<VideoFeedList> {
  final _activeVideoNotifier = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _activeVideoNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    return switch (provider.state) {
      FeedState.idle || FeedState.loading when provider.feedVideos.isEmpty =>
        const ShimmerLoader(),
      FeedState.error => _ErrorView(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: () => provider.refresh(force: true)),
      _ => _buildVideoFeed(context, provider),
    };
  }

  Widget _buildVideoFeed(BuildContext context, FeedProvider provider) {
    final videos = provider.feedVideos;
    if (videos.isEmpty) {
      return Center(
          child: Text('No videos found.',
              style: Theme.of(context).textTheme.bodyMedium));
    }
    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 600;
          Widget card(int i) {
            final video = videos[i];
            final channel = ChannelData.byId[video.channelId] ?? ChannelData.fallback;
            return InlineVideoCard(
              key: ValueKey(video.id),
              video: video,
              channel: channel,
              subcategoryTag: 'Long-form',
              saved: provider.isVideoSaved(video.id),
              activeVideoNotifier: _activeVideoNotifier,
              onSave: () => provider.toggleSaved(video),
              onShare: () => Share.share('${video.title}\n${video.watchUrl}'),
            );
          }

          if (desktop) {
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.08,
              ),
              itemCount: videos.length,
              itemBuilder: (_, i) => card(i),
            );
          }

          return ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: videos.length,
            itemBuilder: (_, i) => Padding(
              key: ValueKey('v_${videos[i].id}'),
              padding: const EdgeInsets.only(bottom: 14),
              child: card(i),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.textMuted(context)),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
