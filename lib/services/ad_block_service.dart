import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'network_policy.dart';

enum AdBlockStatus {
  checking, // initial / between checks
  clear,    // no ad blocker detected
  blocked,  // ad blocker confirmed
}

/// Ad-block detection strategy:
///
/// 1. ONLY runs when ConnectivityService confirms real internet (online).
/// 2. First re-verifies internet independently using two NON-ad endpoints so a
///    general network failure cannot be misread as ad-blocking.
/// 3. Probes a bounded three-endpoint sample. Requires ALL sampled endpoints
///    to fail before flagging as blocked — tolerates individual CDN blips.
/// 4. Distinguishes DNS-level blocking (SocketException / timeout) from HTTP
///    errors — only DNS/TCP failures count as "blocked"; a 403 from the ad
///    server itself does not.
/// 5. Re-checks every 30 minutes while online; ad-block status is non-critical
///    and should not compete with feed traffic.
class AdBlockService {
  AdBlockService._();
  static final AdBlockService instance = AdBlockService._();

  final _statusController = StreamController<AdBlockStatus>.broadcast();
  Stream<AdBlockStatus> get statusStream => _statusController.stream;

  AdBlockStatus _current = AdBlockStatus.checking;
  AdBlockStatus get current => _current;

  bool _disposed = false;
  bool _initialized = false;
  Timer? _periodicTimer;
  StreamSubscription<NetworkStatus>? _connectivitySub;
  Future<void>? _checkInFlight;

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized || _disposed) return;
    _initialized = true;

    // Ad-block probing relies on DNS/TCP failure signatures that are not
    // meaningful in a browser (extensions, CORS). Skip on web.
    if (kIsWeb) {
      _emit(AdBlockStatus.clear);
      return;
    }

    // React to connectivity changes
    _connectivitySub = ConnectivityService.instance.statusStream.listen((status) {
      if (_disposed) return;
      if (status == NetworkStatus.online) {
        if (!NetworkPolicy.instance.isConstrained) {
          unawaited(runCheck());
          _startPeriodicCheck();
        } else {
          _periodicTimer?.cancel();
        }
      } else {
        // No internet — cannot determine ad-block status; reset quietly.
        _periodicTimer?.cancel();
        _emit(AdBlockStatus.checking);
      }
    });

    // Run immediately if already online
    if (ConnectivityService.instance.current == NetworkStatus.online) {
      await runCheck();
      if (!NetworkPolicy.instance.isConstrained) _startPeriodicCheck();
    }
  }

  void _startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (!NetworkPolicy.instance.isConstrained &&
          ConnectivityService.instance.current == NetworkStatus.online) {
        unawaited(runCheck());
      }
    });
  }

  // ── Core Check ───────────────────────────────────────────────────────────────
  Future<void> runCheck() {
    if (_disposed) return Future<void>.value();
    final existing = _checkInFlight;
    if (existing != null) return existing;

    final future = _performCheck();
    _checkInFlight = future;
    return future;
  }

  Future<void> _performCheck() async {
    try {
      // Step 1 — Re-verify internet with neutral endpoints before touching ad URLs.
      // If neutral endpoints also fail, it's a network issue, NOT an ad blocker.
      final internetOk = await _verifyNeutralInternet();
      if (!internetOk) {
        // Network is actually down — don't change status, don't flag as blocked.
        return;
      }

      // Step 2 — Probe ad-network endpoints.
      var dnsBlockCount = 0;

      final endpoints =
          AppConfig.adCheckEndpoints.take(3).toList(growable: false);
      final futures = endpoints.map((url) async {
        try {
          final response = await http
              .get(
                Uri.parse(url),
                headers: {
                  'User-Agent':
                      'Dalvik/2.1.0 (Linux; U; Android 13; Pixel 6 Build/TP1A)',
                  'Accept': '*/*',
                },
              )
              .timeout(const Duration(seconds: 8));

          // HTTP 2xx / 3xx → endpoint reachable → NOT blocked at network level.
          // HTTP 4xx/5xx from ad server itself is NOT an ad blocker — the server
          // is responding, so DNS resolved and TCP connected successfully.
          if (response.statusCode >= 200 && response.statusCode < 500) {
            // Reachable — not blocked
          } else {
            // 5xx — server error, not ad block; don't count.
          }
        } on TimeoutException catch (_) {
          // Silently blocked (null-routes / sinkhole) — ad-blocker signature.
          dnsBlockCount++;
        } on Exception catch (e) {
          // SocketException / HandshakeException (dart:io) only exist on VM.
          // Match by type name so this file stays web-safe without importing dart:io.
          final name = e.runtimeType.toString();
          if (name.contains('Socket') || name.contains('Handshake')) {
            dnsBlockCount++;
          }
          // Other network exception — be conservative, don't count.
        }
      });

      await Future.wait(futures);

      // Only flag as blocked when all sampled ad endpoints fail at network/DNS level
      // while neutral internet is confirmed working. This eliminates false positives.
      final isBlocked = dnsBlockCount >= endpoints.length;
      _emit(isBlocked ? AdBlockStatus.blocked : AdBlockStatus.clear);
    } finally {
      _checkInFlight = null;
    }
  }

  // ── Neutral Internet Verification ─────────────────────────────────────────────
  /// Uses two non-ad Google endpoints. If both fail, the device has no
  /// internet, not an ad blocker. One successful probe is enough to continue.
  Future<bool> _verifyNeutralInternet() async {
    var successCount = 0;
    final futures = AppConfig.connectivityEndpoints.take(2).map((url) async {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode >= 200 && response.statusCode < 400) {
          successCount++;
        }
      } on Exception catch (_) {
        // endpoint unreachable
      }
    });
    await Future.wait(futures);
    return successCount >= 1;
  }

  void _emit(AdBlockStatus status) {
    if (_disposed) return;
    if (status != _current) {
      _current = status;
      _statusController.add(status);
    }
  }

  void dispose() {
    _disposed = true;
    _periodicTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    _statusController.close();
  }
}
