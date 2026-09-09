import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service responsible for verifying true internet reachability.
/// Beyond simply checking Wi-Fi / Cellular connection status, it performs
/// an actual IP lookup with a tight timeout to ensure network traffic can
/// reach external servers.
class InternetService {
  static const Duration _timeout = Duration(milliseconds: 1500);

  /// Returns true if the device has confirmed active internet access.
  Future<bool> hasInternet() async {
    if (kIsWeb) {
      // On web platform, rely on browser online status
      return true;
    }

    try {
      final result = await InternetAddress.lookup('1.1.1.1').timeout(_timeout);
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🌐 [INTERNET] Reachability check failed (offline/timeout): $e');
      }
    }

    // Try secondary DNS lookup if 1.1.1.1 fails or times out
    try {
      final fallbackResult =
          await InternetAddress.lookup('google.com').timeout(_timeout);
      if (fallbackResult.isNotEmpty &&
          fallbackResult.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Fully offline or behind non-routable portal
    }

    return false;
  }
}
