import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/information_form.dart';
import '../providers/feed_provider.dart';
import '../services/notification_store.dart';
import '../services/scroll_visibility_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_shelf.dart';
import '../widgets/rumuo_mark.dart';
import 'content_search_screen.dart';
import 'notifications_screen.dart';

/// The Feed screen — a single vertically-scrolling page made of five
/// shelves, one per [InformationForm] (Videos, Shorts, Audio, Written,
/// Structured/Interactive). Each shelf's subcategories scroll
/// horizontally; the shelves themselves stack vertically.
///
/// The header (logo + notifications) and the search bar sit above the
/// shelves and collapse away while the feed is scrolling, returning as
/// soon as scrolling stops — see [ScrollVisibilityService].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: ScrollVisibilityService.instance.visible,
              builder: (context, visible, child) => AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: visible ? child : const SizedBox(width: double.infinity, height: 0),
              ),
              child: const _HeaderAndSearch(),
            ),
            const Expanded(child: _FeedBody()),
          ],
        ),
      ),
    );
  }
}

// ── Header: logo, notifications, search bar ─────────────────────────────────
class _HeaderAndSearch extends StatelessWidget {
  const _HeaderAndSearch();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const RumuoMark(size: 44, borderRadius: 12),
              const SizedBox(width: 10),
              Text(
                'Rumuo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const Spacer(),
              ValueListenableBuilder<int>(
                valueListenable: NotificationStore.instance.unreadCount,
                builder: (context, count, _) {
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IconButton(
                      icon: Icon(
                        count > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
                        color: count > 0 ? AppTheme.gold : AppTheme.textMuted(context),
                      ),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _SearchBar(
            onTap: () {
              final feedProvider = context.read<FeedProvider>();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ContentSearchScreen(feedProvider: feedProvider)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor(context), width: 0.6),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppTheme.textMuted(context), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search Rumuo — videos, books, blogs & more',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textMuted(context), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feed body: five vertically-stacked shelves ──────────────────────────────
class _FeedBody extends StatelessWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: ScrollVisibilityService.instance.handleScrollNotification,
      child: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: () => context.read<FeedProvider>().refresh(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          padding: const EdgeInsets.only(top: 4, bottom: 120),
          children: const [
            FeedShelf(form: InformationForm.videos),
            FeedShelf(form: InformationForm.shorts),
            FeedShelf(form: InformationForm.audio),
            FeedShelf(form: InformationForm.written),
            FeedShelf(form: InformationForm.structured),
          ],
        ),
      ),
    );
  }
}
