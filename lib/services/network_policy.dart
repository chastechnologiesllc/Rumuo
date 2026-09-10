import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';

enum DataSaverMode { automatic, on, off }

/// Shared policy for network-heavy work.
///
/// The default is adaptive: cellular connections use the low-data profile,
/// while Wi-Fi/ethernet keep the fuller experience. Users can explicitly turn
/// Data Saver on or off from Profile. Keeping this decision in one service
/// prevents each screen from inventing a different definition of "slow".
class NetworkPolicy extends ChangeNotifier {
  NetworkPolicy._();
  static final NetworkPolicy instance = NetworkPolicy._();

  static const String prefDataSaverMode = 'network_data_saver_mode';

  DataSaverMode _mode = DataSaverMode.automatic;
  ConnectivityResult _transport = ConnectivityResult.none;
  bool _initialized = false;
  bool _disposed = false;
  StreamSubscription<List<ConnectivityResult>>? _transportSub;

  DataSaverMode get mode => _mode;
  ConnectivityResult get transport => _transport;
  bool get isInitialized => _initialized;

  bool get isCellular => _transport == ConnectivityResult.mobile;

  /// Effective low-data mode. Unknown transport is treated conservatively so
  /// cold starts do not briefly create a full request burst.
  bool get isDataSaverEnabled => switch (_mode) {
      DataSaverMode.on => true,
      DataSaverMode.off => false,
      // Before the first connectivity event, prefer the economical profile so
      // a cold launch cannot briefly start a full request burst. This also
      // covers browsers, whose transport signal is often unavailable.
      DataSaverMode.automatic => isCellular || _transport == ConnectivityResult.none,
      };

  bool get isConstrained => isDataSaverEnabled;

  /// Number of simultaneous feed requests. Lower concurrency avoids radio,
  /// memory, and proxy contention on entry-level devices and mobile data.
  int get feedConcurrency => isConstrained ? 2 : 5;

  /// Blog feeds are larger and often require a second HTML request when a
  /// catalog URL is used. Keep their worker pool smaller than video feeds.
  int get blogConcurrency => isConstrained ? 2 : 5;

  /// Retries are useful on a flaky connection, but repeating a large request
  /// can cost more data than it saves. One retry is enough in Data Saver.
  int get maxRequestAttempts => isConstrained ? 2 : 3;

  /// The full history screen is an opt-in enhancement. The first 15 Atom
  /// entries are enough to make the channel usable everywhere.
  bool get allowHistoryEnrichment => !isConstrained;

  /// Prewarming a YouTube WebView downloads far more than a thumbnail. Never
  /// do it merely because a card became visible on a constrained connection.
  bool get allowVideoPrewarm => !isConstrained;

  /// Article-page thumbnail hydration is a background HTML crawl, not a core
  /// feed operation. It is disabled in Data Saver.
  bool get allowArticleImageHydration => !isConstrained;

  /// Proxy races duplicate the same response. A sequential fallback is more
  /// economical and still recovers from a dead proxy.
  int get maxProxyCandidates => isConstrained ? 1 : 2;

  Future<void> init() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefDataSaverMode);
      _mode = switch (raw) {
        'on' => DataSaverMode.on,
        'off' => DataSaverMode.off,
        _ => DataSaverMode.automatic,
      };
    } on Object catch (_) {
      _mode = DataSaverMode.automatic;
    }

    _transport = ConnectivityService.instance.transport.firstWhere(
      (item) => item != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
    _transportSub = ConnectivityService.instance.transportStream.listen((result) {
      final next = result.firstWhere(
        (item) => item != ConnectivityResult.none,
        orElse: () => ConnectivityResult.none,
      );
      if (next == _transport) return;
      final wasConstrained = isConstrained;
      _transport = next;
      if (wasConstrained != isConstrained) notifyListeners();
    });
  }

  Future<void> setMode(DataSaverMode mode) async {
    if (_disposed || mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefDataSaverMode, mode.name);
    } on Object catch (_) {
      // The in-memory setting still protects this session if disk persistence
      // is temporarily unavailable.
    }
  }

  Future<void> toggle() async {
    await setMode(isDataSaverEnabled ? DataSaverMode.off : DataSaverMode.on);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_transportSub?.cancel());
    super.dispose();
  }
}
