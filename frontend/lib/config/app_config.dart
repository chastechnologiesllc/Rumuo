/// Central configuration for Rumuo — by chAs Technologies LLC
class AppConfig {
  AppConfig._();

  static const String appName = 'Rumuo';
  static const String byLine = 'by chAs Technologies LLC';
  static const String company = 'chAs Technologies LLC';
  static const String packageName = 'com.chastechgroup.rumuo';

  // ── Shared application settings ──────────────────────────────────────────────

  // ── SharedPreferences Keys ───────────────────────────────────────────────────
  // ── In-app notification inbox ─────────────────────────────────────────────────
  /// JSON-encoded list of [NotificationItem] — written by both the background
  /// WorkManager isolate (via NotificationStore.appendToPrefsStatic) and the
  /// main isolate.
  static const String prefInAppNotifications = 'in_app_notifications';

  /// Persisted unread badge count — incremented by the background isolate,
  /// reset to 0 by the main isolate when the user opens the inbox.
  static const String prefNotifUnreadCount   = 'notif_unread_count';

  /// Maximum number of notification items kept in the inbox.
  static const int notifInboxMaxItems = 50;
  static const String prefLastSeenVideos       = 'last_seen_videos_';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefSavedVideos          = 'saved_videos';
  static const String prefSavedBookmarks       = 'saved_bookmarks';
  static const String prefSelectedCategoryIds  = 'selected_resource_category_ids';
  static const String prefOnboardingComplete   = 'onboarding_complete';
  static const String prefChannelEngagement    = 'channel_engagement_scores';
  static const String prefCategoryEngagement   = 'category_engagement_scores';
  static const String prefEngagementDecayAt    = 'engagement_last_decay_ms';

  // ── Connectivity ─────────────────────────────────────────────────────────────
  static const List<String> connectivityEndpoints = [
    'https://www.gstatic.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://clients3.google.com/generate_204',
    'https://www.google.com/favicon.ico',
  ];

  /// Browser-safe probes. Google generate_204 responses omit
  /// Access-Control-Allow-Origin, so XHR from github.io is blocked and
  /// every probe appears to fail → false "No internet". These endpoints
  /// return ACAO and work from a browser origin.
  static const List<String> connectivityEndpointsWeb = [
    'https://httpbin.org/status/204',
    'https://cloudflare.com/cdn-cgi/trace',
  ];

  // ── Background Task ───────────────────────────────────────────────────────────
  // Must match Info.plist → BGTaskSchedulerPermittedIdentifiers
  static const String rssCheckTaskId      = 'com.chastechgroup.rumuo.rsscheck';
  static const String rssCheckTaskName    = 'rssCheckTask';
  static const Duration rssCheckFrequency = Duration(minutes: 15);

  // ── Notification Channel ──────────────────────────────────────────────────────
  static const int    notifIdBase      = 1000;
  static const String notifChannelId   = 'rumuo_new_content';
  static const String notifChannelName = 'New Videos';
  static const String notifChannelDesc =
      'Get notified when your favourite channels post new content';
}
