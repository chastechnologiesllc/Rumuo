import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/channel_data.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../screens/video_player_screen.dart';
import '../services/notification_service.dart';
import '../services/notification_store.dart';
import '../services/scroll_visibility_service.dart';
import '../theme/app_theme.dart';
import '../widgets/no_flash_page_route.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _handlingPendingDeepLink = false;

  static const _screens = [
    HomeScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Handles cold-launch deep link (app was not running when notif was tapped).
    _schedulePendingDeepLink(waitForColdStart: true);
  }

  void _schedulePendingDeepLink({bool waitForColdStart = false}) {
    if (_handlingPendingDeepLink ||
        (!waitForColdStart && NotificationService.pendingVideoId == null)) {
      return;
    }
    _handlingPendingDeepLink = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handlePendingDeepLink().whenComplete(() {
        _handlingPendingDeepLink = false;
      }));
    });
  }

  /// Full deep-link handler. Works for both cold and warm launches.
  ///
  /// Four guarantees:
  /// 1. Waits for [NotificationService.pendingVideoId] to be set, since
  ///    NotificationService.init() now runs in the background (fire-and-
  ///    forget, for fast startup) and may not have resolved the cold-start
  ///    launch details the instant this widget first builds.
  /// 2. Waits for the feed to be populated before searching (cold-launch safe).
  /// 3. Looks up the [Channel] for the video before pushing (avoids compile crash).
  /// 4. Consumes [pendingVideoId] immediately so it never fires twice.
  Future<void> _handlePendingDeepLink() async {
    if (!mounted) return;

    // ── Wait for the deep link itself ───────────────────────────────────────
    // NotificationService.init() (which performs the cold-start launch-
    // detail lookup) is fire-and-forget from app startup for speed — it may
    // genuinely still be running when MainShell first builds. Poll briefly
    // rather than checking once and giving up.
    const dlMaxWaitMs = 5000;
    const dlPollMs    = 100;
    var   dlWaited    = 0;
    while (NotificationService.pendingVideoId == null && dlWaited < dlMaxWaitMs) {
      await Future<void>.delayed(const Duration(milliseconds: dlPollMs));
      dlWaited += dlPollMs;
      if (!mounted) return;
    }

    final videoId = NotificationService.pendingVideoId;
    if (videoId == null || !mounted) return;
    NotificationService.pendingVideoId = null; // consume immediately

    final provider = context.read<FeedProvider>();

    // ── Wait for feed data ─────────────────────────────────────────────────
    // On a cold launch the provider may not have data yet (disk cache + network
    // fetch are still in progress). Poll every 200 ms for up to 8 seconds.
    const maxWaitMs  = 8000;
    const pollMs     = 200;
    var   waited     = 0;
    while (provider.allVideos.every((tab) => tab.isEmpty) && waited < maxWaitMs) {
      await Future<void>.delayed(const Duration(milliseconds: pollMs));
      waited += pollMs;
      if (!mounted) return;
    }

    // ── Search every tab for the video ────────────────────────────────────
    Video? video;
    for (final tab in provider.allVideos) {
      try {
        video = tab.firstWhere((v) => v.id == videoId);
        break;
      } on StateError {
        continue;
      }
    }

    if (video == null || !mounted) return;

    // ── Look up the channel (required by VideoPlayerScreen) ───────────────
    final channel = ChannelData.byId[video.channelId] ?? ChannelData.fallback;

    // Switch to Feed tab then push the video player
    setState(() => _index = 0);
    await Navigator.of(context).push(
      NoFlashPageRoute(
        builder: (_) => VideoPlayerScreen(video: video!, channel: channel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warm-launch: app was already running when notification was tapped.
    _schedulePendingDeepLink();

    return Scaffold(
      body: Column(
        children: [
          _TopNavigation(
            currentIndex: _index,
            onTap: (i) {
              if (i == _index) return;
              ScrollVisibilityService.instance.show();
              setState(() => _index = i);
            },
          ),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
    );
  }
}

class _TopNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TopNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined,    Icons.home_rounded,     'Feed'),
    (Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Saved'),
    (Icons.person_outline_rounded,   Icons.person_rounded,   'Profile'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 2),
          child: Row(
            children: [
              Text('Rumuo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 28, fontWeight: FontWeight.w800)),
              const Spacer(),
              _TopNavButton(
                  icon: _items[0], active: currentIndex == 0, onTap: () => onTap(0)),
              _TopNavButton(
                  icon: _items[1], active: currentIndex == 1, onTap: () => onTap(1)),
              ValueListenableBuilder<int>(
                valueListenable: NotificationStore.instance.unreadCount,
                builder: (_, count, __) => Badge(
                  isLabelVisible: count > 0,
                  label: Text(count > 99 ? '99+' : '$count'),
                  child: IconButton(
                    tooltip: 'Notifications',
                    icon: Icon(count > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined),
                    color: count > 0 ? AppTheme.gold : AppTheme.textMuted(context),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                  ),
                ),
              ),
              _TopNavButton(
                  icon: _items[2], active: currentIndex == 2, onTap: () => onTap(2)),
            ],
          ),
        ),
      );
}

class _TopNavButton extends StatelessWidget {
  final (IconData, IconData, String) icon;
  final bool active;
  final VoidCallback onTap;
  const _TopNavButton({required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: icon.$3,
        onPressed: onTap,
        icon: Icon(active ? icon.$2 : icon.$1,
            color: active ? AppTheme.gold : AppTheme.textMuted(context)),
      );
}
