/// Central configuration for Rumuo — by chAs Technologies LLC
class AppConfig {
  AppConfig._();

  static const String appName    = 'Rumuo';
  static const String byLine     = 'by chAs Technologies LLC';
  static const String company    = 'chAs Technologies LLC';
  static const String packageName = 'com.chastechgroup.rumuo';

  /// Production Rumuo experience API.
  /// Override at build time with:
  ///   --dart-define=RUMUO_API_BASE_URL=https://your-custom-domain.com/api/resources
  static const String resourceApiBaseUrl = String.fromEnvironment(
    'RUMUO_API_BASE_URL',
    defaultValue: 'https://rumuo-api-ch-as-technologies-llc.vercel.app/api/resources',
  );

  // ── SharedPreferences Keys ────────────────────────────────────────────────────
  static const String prefInAppNotifications   = 'in_app_notifications';
  static const String prefNotifUnreadCount     = 'notif_unread_count';
  static const int    notifInboxMaxItems        = 50;
  static const String prefLastSeenVideos        = 'last_seen_videos_';
  static const String prefNotificationsEnabled  = 'notifications_enabled';
  static const String prefSavedVideos           = 'saved_videos';
  static const String prefSavedBookmarks        = 'saved_bookmarks';
  static const String prefSelectedCategoryIds   = 'selected_resource_category_ids';
  static const String prefOnboardingComplete    = 'onboarding_complete';
  static const String prefChannelEngagement     = 'channel_engagement_scores';
  static const String prefCategoryEngagement    = 'category_engagement_scores';
  static const String prefEngagementDecayAt     = 'engagement_last_decay_ms';

  // ── Connectivity ──────────────────────────────────────────────────────────────
  static const List<String> connectivityEndpoints = [
    'https://www.gstatic.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://clients3.google.com/generate_204',
    'https://www.google.com/favicon.ico',
  ];

  static const List<String> connectivityEndpointsWeb = [
    'https://httpbin.org/status/204',
    'https://cloudflare.com/cdn-cgi/trace',
  ];

  // ── Background Task ───────────────────────────────────────────────────────────
  static const String   rssCheckTaskId      = 'com.chastechgroup.rumuo.rsscheck';
  static const String   rssCheckTaskName    = 'rssCheckTask';
  static const Duration rssCheckFrequency   = Duration(minutes: 15);

  // ── Notification Channel ──────────────────────────────────────────────────────
  static const int    notifIdBase      = 1000;
  static const String notifChannelId   = 'rumuo_new_content';
  static const String notifChannelName = 'New Content';
  static const String notifChannelDesc =
      'Get notified when new medical content is available for you';
}
