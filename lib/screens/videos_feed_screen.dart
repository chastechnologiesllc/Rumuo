import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/feed_tab.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/video_feed_list.dart';

/// Standalone "Videos" destination — the Long-form subcategory under the
/// Videos shelf. Reuses the same FeedProvider video tab the rest of the
/// app already relies on; no backend change involved.
class VideosFeedScreen extends StatefulWidget {
  const VideosFeedScreen({super.key});

  @override
  State<VideosFeedScreen> createState() => _VideosFeedScreenState();
}

class _VideosFeedScreenState extends State<VideosFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FeedProvider>().setTab(FeedTab.videos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Videos — Long-form'),
      ),
      body: const VideoFeedList(),
    );
  }
}
