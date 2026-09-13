import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'blog_feed_screen.dart';

/// Standalone "Blogs" destination — the Blogs subcategory under the
/// Written shelf. BlogFeedScreen itself is body-only (no AppBar), so
/// this just gives it a Scaffold to be pushed as its own screen.
class BlogsFeedScreen extends StatelessWidget {
  const BlogsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Blogs'),
      ),
      body: const BlogFeedScreen(),
    );
  }
}
