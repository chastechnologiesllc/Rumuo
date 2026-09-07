import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/feed_tab.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/books_list.dart';

/// Standalone "Books" destination — the Books subcategory under the
/// Written shelf. Reuses the same FeedProvider books tab the rest of
/// the app already relies on; no backend change involved.
class BooksFeedScreen extends StatefulWidget {
  const BooksFeedScreen({super.key});

  @override
  State<BooksFeedScreen> createState() => _BooksFeedScreenState();
}

class _BooksFeedScreenState extends State<BooksFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FeedProvider>().setTab(FeedTab.books);
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
        title: const Text('Books'),
      ),
      body: const BooksList(),
    );
  }
}
