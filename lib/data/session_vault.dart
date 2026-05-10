import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers who is logged in locally. Uses secure storage where available and
/// mirrors into [SharedPreferences] so the UX stays coherent across platforms.
class SessionVault {
  SessionVault();

  static const _k = 'study_pal.active_public_user_id';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<void> rememberUser(String publicUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k, publicUserId);
    if (kIsWeb) return;

    await _secure.write(key: _k, value: publicUserId);
  }

  Future<String?> activePublicUserId() async {
    if (!kIsWeb) {
      try {
        final fromSecure = await _secure.read(key: _k);
        if (fromSecure != null && fromSecure.isNotEmpty) return fromSecure;
      } catch (_) {
        // Fall through to prefs.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_k);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_k);
    if (kIsWeb) return;

    try {
      await _secure.delete(key: _k);
    } catch (_) {
      // Best-effort.
    }
  }
}
