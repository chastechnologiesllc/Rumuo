import 'package:shared_preferences/shared_preferences.dart';

/// Local browser-style state for Rumuo search sessions.
///
/// Private searches never write to this store. Normal searches keep only the
/// most recent unique queries so the sessions screen stays fast on mobile and
/// desktop.
class SearchSessionStore {
  SearchSessionStore._();

  static const String _sessionsKey = 'rumuo_search_sessions';
  static const String _privateSearchKey = 'rumuo_private_search_enabled';
  static const int maxSessions = 99;

  static Future<List<String>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_sessionsKey) ?? <String>[];
  }

  static Future<void> add(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList(_sessionsKey) ?? <String>[];
    sessions.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
    sessions.insert(0, normalized);
    if (sessions.length > maxSessions) {
      sessions.removeRange(maxSessions, sessions.length);
    }
    await prefs.setStringList(_sessionsKey, sessions);
  }

  static Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList(_sessionsKey) ?? <String>[];
    sessions.remove(query);
    await prefs.setStringList(_sessionsKey, sessions);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  static Future<bool> privateSearchEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privateSearchKey) ?? true;
  }

  static Future<void> setPrivateSearchEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privateSearchKey, enabled);
  }
}
